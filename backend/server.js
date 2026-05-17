const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');

const cors = require('cors');
const express = require('express');
const sql = require('mssql');

const app = express();
const port = Number.parseInt(process.env.PORT || '8080', 10);

app.use(cors());
app.use(express.json({ limit: '1mb' }));

const sessions = new Map();
const SESSION_IDLE_MS = 30 * 60 * 1000;

app.get('/health', (_req, res) => {
  res.json({ ok: true, timestamp: new Date().toISOString() });
});

app.post('/connect', async (req, res) => {
  try {
    validateConnectionPayload(req.body);
    const config = buildSqlConfig(req.body);
    const pool = await createPoolWithDatabaseBootstrap(req.body);

    const token = crypto.randomUUID();
    sessions.set(token, {
      pool,
      config,
      lastUsedAt: Date.now(),
    });

    res.json({ token });
  } catch (error) {
    const normalized = normalizeConnectionError(error);
    res.status(400).json({ error: normalized.message || 'Unable to connect.' });
  }
});

app.post('/disconnect', requireSession, async (req, res) => {
  try {
    await req.session.pool.close();
  } catch (_) {
    // No-op. We still clear the session token.
  }

  sessions.delete(req.sessionToken);
  res.json({ ok: true });
});

app.post('/setup', requireSession, async (req, res) => {
  try {
    const batches = await runSchema(req.session.pool);
    res.json({ ok: true, executedBatches: batches });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Schema setup failed.' });
  }
});

app.get('/dashboard', requireSession, async (req, res) => {
  try {
    const result = await executeQuery(
      req.session.pool,
      `
SELECT
  (SELECT COUNT(*) FROM dbo.Members WHERE Status = 'ACTIVE') AS ActiveMembers,
  (
    SELECT ISNULL(SUM(SavingsBalance), 0.00)
    FROM dbo.vMemberSavingsBalance
  ) AS TotalSavings,
  (
    SELECT COUNT(*)
    FROM dbo.LoanAccounts
    WHERE Status = 'APPROVED'
  ) AS ActiveLoans,
  (
    SELECT ISNULL(SUM(TotalOutstanding), 0.00)
    FROM dbo.vLoanOutstanding
    WHERE Status = 'APPROVED'
  ) AS TotalLoanOutstanding;
`,
    );

    const row = result.recordset?.[0] || {
      ActiveMembers: 0,
      TotalSavings: 0,
      ActiveLoans: 0,
      TotalLoanOutstanding: 0,
    };
    res.json(row);
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to load dashboard.' });
  }
});

app.get('/members', requireSession, async (req, res) => {
  try {
    const result = await executeQuery(
      req.session.pool,
      `
SELECT
  m.MemberId,
  m.MemberNumber,
  m.FullName,
  ISNULL(m.PhoneNumber, '') AS PhoneNumber,
  ISNULL(m.AddressLine, '') AS AddressLine,
  m.JoinedDate,
  m.Status,
  ISNULL(b.SavingsBalance, 0.00) AS SavingsBalance
FROM dbo.Members m
LEFT JOIN dbo.vMemberSavingsBalance b
  ON b.MemberId = m.MemberId
ORDER BY m.MemberId DESC;
`,
    );

    res.json({ rows: result.recordset || [] });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to load members.' });
  }
});

app.post('/members', requireSession, async (req, res) => {
  try {
    const fullName = cleanString(req.body.fullName);
    const phoneNumber = cleanString(req.body.phoneNumber);
    const addressLine = cleanString(req.body.addressLine);
    const joinedDate = cleanString(req.body.joinedDate) || dateOnly(new Date());

    if (!fullName) {
      return res.status(400).json({ error: 'fullName is required.' });
    }

    const memberNumber = await nextMemberNumber(req.session.pool);
    const insertResult = await executeQuery(
      req.session.pool,
      `
DECLARE @newMember TABLE (MemberId INT);
INSERT INTO dbo.Members (
  MemberNumber,
  FullName,
  PhoneNumber,
  AddressLine,
  JoinedDate,
  Status
)
OUTPUT INSERTED.MemberId INTO @newMember(MemberId)
VALUES (
  @memberNumber,
  @fullName,
  @phoneNumber,
  @addressLine,
  @joinedDate,
  'ACTIVE'
);
SELECT TOP 1 MemberId FROM @newMember;
`,
      {
        memberNumber,
        fullName,
        phoneNumber,
        addressLine,
        joinedDate,
      },
    );

    const memberId = insertResult.recordset?.[0]?.MemberId;
    res.status(201).json({ memberId, memberNumber });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to create member.' });
  }
});

app.patch('/members/:memberId/status', requireSession, async (req, res) => {
  try {
    const memberId = toInt(req.params.memberId);
    const status = cleanString(req.body.status).toUpperCase();

    if (!memberId) {
      return res.status(400).json({ error: 'memberId is invalid.' });
    }
    if (!['ACTIVE', 'INACTIVE'].includes(status)) {
      return res.status(400).json({ error: 'status must be ACTIVE or INACTIVE.' });
    }

    const memberResult = await executeQuery(
      req.session.pool,
      `
SELECT TOP 1 MemberId, Status
FROM dbo.Members
WHERE MemberId = @memberId;
`,
      { memberId },
    );

    if (!memberResult.recordset?.length) {
      return res.status(404).json({ error: 'Member not found.' });
    }

    if (status === 'INACTIVE') {
      const openLoanCheck = await executeQuery(
        req.session.pool,
        `
SELECT COUNT(*) AS OpenLoanCount
FROM dbo.vLoanOutstanding
WHERE MemberId = @memberId
  AND Status = 'APPROVED'
  AND TotalOutstanding > 0;
`,
        { memberId },
      );

      if (toInt(openLoanCheck.recordset?.[0]?.OpenLoanCount) > 0) {
        return res.status(409).json({
          error:
            'Member has active loan balances. Settle outstanding approved loans before inactivation.',
        });
      }
    }

    await executeQuery(
      req.session.pool,
      `
UPDATE dbo.Members
SET Status = @status,
    UpdatedAt = SYSDATETIME()
WHERE MemberId = @memberId;
`,
      { memberId, status },
    );

    res.json({ ok: true, memberId, status });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to update member status.' });
  }
});

app.delete('/members/:memberId', requireSession, async (req, res) => {
  try {
    const memberId = toInt(req.params.memberId);

    if (!memberId) {
      return res.status(400).json({ error: 'memberId is invalid.' });
    }

    const memberResult = await executeQuery(
      req.session.pool,
      `
SELECT TOP 1 MemberId
FROM dbo.Members
WHERE MemberId = @memberId;
`,
      { memberId },
    );

    if (!memberResult.recordset?.length) {
      return res.status(404).json({ error: 'Member not found.' });
    }

    const dependencyResult = await executeQuery(
      req.session.pool,
      `
SELECT
  (SELECT COUNT(*) FROM dbo.SavingsTransactions WHERE MemberId = @memberId) AS SavingsCount,
  (SELECT COUNT(*) FROM dbo.LoanAccounts WHERE MemberId = @memberId) AS LoanCount;
`,
      { memberId },
    );

    const deps = dependencyResult.recordset?.[0] || {};
    const savingsCount = toInt(deps.SavingsCount);
    const loanCount = toInt(deps.LoanCount);

    if (savingsCount > 0 || loanCount > 0) {
      return res.status(409).json({
        error:
          'Member cannot be deleted because financial records already exist. Set member status to INACTIVE instead.',
      });
    }

    await executeQuery(
      req.session.pool,
      `
DELETE FROM dbo.Members
WHERE MemberId = @memberId;
`,
      { memberId },
    );

    res.json({ ok: true, memberId });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to delete member.' });
  }
});

app.post('/savings-transactions', requireSession, async (req, res) => {
  try {
    const memberId = toInt(req.body.memberId);
    const transactionType = cleanString(req.body.transactionType).toUpperCase();
    const amount = toNumber(req.body.amount);
    const transactionDate =
      cleanString(req.body.transactionDate) || dateOnly(new Date());
    const referenceNo = cleanString(req.body.referenceNo);
    const remarks = cleanString(req.body.remarks);

    if (!memberId) {
      return res.status(400).json({ error: 'memberId is required.' });
    }
    if (!['DEPOSIT', 'WITHDRAWAL'].includes(transactionType)) {
      return res.status(400).json({ error: 'transactionType must be DEPOSIT or WITHDRAWAL.' });
    }
    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ error: 'amount must be greater than 0.' });
    }

    const memberResult = await executeQuery(
      req.session.pool,
      `
SELECT TOP 1 Status
FROM dbo.Members
WHERE MemberId = @memberId;
`,
      { memberId },
    );

    const memberStatus = memberResult.recordset?.[0]?.Status;
    if (!memberStatus) {
      return res.status(404).json({ error: 'Member not found.' });
    }
    if (String(memberStatus).toUpperCase() !== 'ACTIVE') {
      return res.status(409).json({ error: 'Savings transactions are allowed only for active members.' });
    }

    await executeQuery(
      req.session.pool,
      `
INSERT INTO dbo.SavingsTransactions (
  MemberId,
  TransactionDate,
  TransactionType,
  Amount,
  ReferenceNo,
  Remarks
)
VALUES (
  @memberId,
  @transactionDate,
  @transactionType,
  @amount,
  @referenceNo,
  @remarks
);
`,
      {
        memberId,
        transactionDate,
        transactionType,
        amount,
        referenceNo,
        remarks,
      },
    );

    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to record savings transaction.' });
  }
});

app.get('/members/:memberId/savings-transactions', requireSession, async (req, res) => {
  try {
    const memberId = toInt(req.params.memberId);
    const limit = clamp(toInt(req.query.limit) || 100, 1, 500);

    if (!memberId) {
      return res.status(400).json({ error: 'memberId is invalid.' });
    }

    const result = await executeQuery(
      req.session.pool,
      `
SELECT TOP (@limit)
  SavingsTransactionId,
  MemberId,
  TransactionDate,
  TransactionType,
  Amount,
  ISNULL(ReferenceNo, '') AS ReferenceNo,
  ISNULL(Remarks, '') AS Remarks
FROM dbo.SavingsTransactions
WHERE MemberId = @memberId
ORDER BY TransactionDate DESC, SavingsTransactionId DESC;
`,
      { memberId, limit },
    );

    res.json({ rows: result.recordset || [] });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to load savings transactions.' });
  }
});

app.get('/members/:memberId/savings-balance', requireSession, async (req, res) => {
  try {
    const memberId = toInt(req.params.memberId);
    if (!memberId) {
      return res.status(400).json({ error: 'memberId is invalid.' });
    }

    const result = await executeQuery(
      req.session.pool,
      `
SELECT TOP 1 ISNULL(SavingsBalance, 0.00) AS SavingsBalance
FROM dbo.vMemberSavingsBalance
WHERE MemberId = @memberId;
`,
      { memberId },
    );

    const balance = result.recordset?.[0]?.SavingsBalance || 0;
    res.json({ SavingsBalance: balance });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to load savings balance.' });
  }
});

app.post('/loans', requireSession, async (req, res) => {
  try {
    const memberId = toInt(req.body.memberId);
    const principalAmount = toNumber(req.body.principalAmount);
    const annualInterestRate = toNumber(req.body.annualInterestRate);
    const termMonths = toInt(req.body.termMonths);
    const purpose = cleanString(req.body.purpose);
    const approvedBy = cleanString(req.body.approvedBy) || 'Manager';
    const approvalDate = cleanString(req.body.approvalDate) || dateOnly(new Date());

    if (!memberId) {
      return res.status(400).json({ error: 'memberId is required.' });
    }
    if (!Number.isFinite(principalAmount) || principalAmount <= 0) {
      return res.status(400).json({ error: 'principalAmount must be greater than 0.' });
    }
    if (!Number.isFinite(annualInterestRate) || annualInterestRate < 0) {
      return res.status(400).json({ error: 'annualInterestRate must be 0 or higher.' });
    }
    if (!termMonths || termMonths <= 0) {
      return res.status(400).json({ error: 'termMonths must be greater than 0.' });
    }

    const memberResult = await executeQuery(
      req.session.pool,
      `
SELECT TOP 1 Status
FROM dbo.Members
WHERE MemberId = @memberId;
`,
      { memberId },
    );

    const memberStatus = memberResult.recordset?.[0]?.Status;
    if (!memberStatus) {
      return res.status(404).json({ error: 'Member not found.' });
    }
    if (String(memberStatus).toUpperCase() !== 'ACTIVE') {
      return res.status(409).json({ error: 'Loans can be created only for active members.' });
    }

    const totalInterestExpected =
      principalAmount * (annualInterestRate / 100) * (termMonths / 12);

    const result = await executeQuery(
      req.session.pool,
      `
DECLARE @newLoan TABLE (LoanId INT);
INSERT INTO dbo.LoanAccounts (
  MemberId,
  ApplicationDate,
  ApprovalDate,
  PrincipalAmount,
  InterestRateAnnual,
  TermMonths,
  TotalInterestExpected,
  Status,
  Purpose,
  ApprovedBy
)
OUTPUT INSERTED.LoanId INTO @newLoan(LoanId)
VALUES (
  @memberId,
  @applicationDate,
  @approvalDate,
  @principalAmount,
  @interestRateAnnual,
  @termMonths,
  @totalInterestExpected,
  'APPROVED',
  @purpose,
  @approvedBy
);
SELECT TOP 1 LoanId FROM @newLoan;
`,
      {
        memberId,
        applicationDate: approvalDate,
        approvalDate,
        principalAmount,
        interestRateAnnual: annualInterestRate,
        termMonths,
        totalInterestExpected,
        purpose,
        approvedBy,
      },
    );

    const loanId = result.recordset?.[0]?.LoanId;
    res.status(201).json({ loanId });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to create loan.' });
  }
});

app.get('/loans', requireSession, async (req, res) => {
  try {
    const result = await executeQuery(
      req.session.pool,
      `
SELECT
  LoanId,
  MemberId,
  MemberNumber,
  MemberName,
  Status,
  PrincipalAmount,
  TotalInterestExpected,
  TotalOutstanding,
  ApprovalDate,
  TermMonths,
  InterestRateAnnual,
  ISNULL(Purpose, '') AS Purpose
FROM dbo.vLoanOutstanding
ORDER BY LoanId DESC;
`,
    );

    res.json({ rows: result.recordset || [] });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to load loans.' });
  }
});

app.post('/loan-payments', requireSession, async (req, res) => {
  try {
    const loanId = toInt(req.body.loanId);
    const paymentDate = cleanString(req.body.paymentDate) || dateOnly(new Date());
    const principalPaid = toNumber(req.body.principalPaid);
    const interestPaid = toNumber(req.body.interestPaid);
    const penaltyPaid = toNumber(req.body.penaltyPaid);
    const remarks = cleanString(req.body.remarks);

    if (!loanId) {
      return res.status(400).json({ error: 'loanId is required.' });
    }

    const totalPayment = principalPaid + interestPaid + penaltyPaid;
    if (!Number.isFinite(totalPayment) || totalPayment <= 0) {
      return res.status(400).json({ error: 'Total payment must be greater than 0.' });
    }

    const loanResult = await executeQuery(
      req.session.pool,
      `
SELECT TOP 1
  Status,
  TotalOutstanding
FROM dbo.vLoanOutstanding
WHERE LoanId = @loanId;
`,
      { loanId },
    );

    const loan = loanResult.recordset?.[0];
    if (!loan) {
      return res.status(404).json({ error: 'Loan not found.' });
    }

    const loanStatus = String(loan.Status || '').toUpperCase();
    const outstanding = toNumber(loan.TotalOutstanding);

    if (loanStatus !== 'APPROVED') {
      return res.status(409).json({ error: 'Payments can be posted only to approved loans.' });
    }

    if (totalPayment > outstanding + 0.005) {
      return res.status(409).json({
        error: `Payment exceeds current outstanding balance (${outstanding.toFixed(2)}).`,
      });
    }

    await executeQuery(
      req.session.pool,
      `
INSERT INTO dbo.LoanPayments (
  LoanId,
  PaymentDate,
  PrincipalPaid,
  InterestPaid,
  PenaltyPaid,
  Remarks
)
VALUES (
  @loanId,
  @paymentDate,
  @principalPaid,
  @interestPaid,
  @penaltyPaid,
  @remarks
);
`,
      {
        loanId,
        paymentDate,
        principalPaid,
        interestPaid,
        penaltyPaid,
        remarks,
      },
    );

    res.json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to record payment.' });
  }
});

app.get('/loans/:loanId/payments', requireSession, async (req, res) => {
  try {
    const loanId = toInt(req.params.loanId);
    const limit = clamp(toInt(req.query.limit) || 100, 1, 500);

    if (!loanId) {
      return res.status(400).json({ error: 'loanId is invalid.' });
    }

    const result = await executeQuery(
      req.session.pool,
      `
SELECT TOP (@limit)
  LoanPaymentId,
  LoanId,
  PaymentDate,
  PrincipalPaid,
  InterestPaid,
  PenaltyPaid,
  ISNULL(Remarks, '') AS Remarks
FROM dbo.LoanPayments
WHERE LoanId = @loanId
ORDER BY PaymentDate DESC, LoanPaymentId DESC;
`,
      { loanId, limit },
    );

    res.json({ rows: result.recordset || [] });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to load loan payments.' });
  }
});

app.get('/reports/monthly', requireSession, async (req, res) => {
  try {
    const year = toInt(req.query.year);
    const month = toInt(req.query.month);

    if (!year || !month || month < 1 || month > 12) {
      return res.status(400).json({ error: 'year and month query params are required.' });
    }

    const result = await executeQuery(
      req.session.pool,
      `
SELECT TOP 1
  ReportYear,
  ReportMonth,
  Deposits,
  Withdrawals,
  NetSavings,
  LoanDisbursements,
  LoanRepayments,
  NetCashFlow
FROM dbo.vMonthlyFinancialSummary
WHERE ReportYear = @reportYear
  AND ReportMonth = @reportMonth;
`,
      {
        reportYear: year,
        reportMonth: month,
      },
    );

    if (!result.recordset?.length) {
      return res.json({ summary: null });
    }

    res.json({ summary: result.recordset[0] });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to load report.' });
  }
});

app.use((error, _req, res, _next) => {
  res.status(500).json({ error: error.message || 'Unexpected server error.' });
});

app.listen(port, () => {
  console.log(`PQR backend listening on http://localhost:${port}`);
});

setInterval(() => {
  void cleanupIdleSessions();
}, 5 * 60 * 1000).unref();

process.on('SIGINT', async () => {
  await closeAllSessions();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await closeAllSessions();
  process.exit(0);
});

function requireSession(req, res, next) {
  const token = parseToken(req);
  if (!token) {
    return res.status(401).json({ error: 'Missing session token. Connect first.' });
  }

  const session = sessions.get(token);
  if (!session) {
    return res.status(401).json({ error: 'Session expired. Connect again.' });
  }

  session.lastUsedAt = Date.now();
  req.session = session;
  req.sessionToken = token;
  next();
}

function parseToken(req) {
  const bearer = req.headers.authorization;
  if (typeof bearer === 'string' && bearer.startsWith('Bearer ')) {
    return bearer.slice('Bearer '.length).trim();
  }

  const fallback = req.headers['x-session-token'];
  if (typeof fallback === 'string' && fallback.trim()) {
    return fallback.trim();
  }

  return null;
}

function validateConnectionPayload(payload) {
  const requiredFields = ['host', 'port', 'database', 'username', 'password'];
  for (const field of requiredFields) {
    const value = payload?.[field];
    if (typeof value !== 'string' || !value.trim()) {
      throw new Error(`${field} is required.`);
    }
  }

  const parsedPort = Number.parseInt(String(payload.port), 10);
  if (!Number.isInteger(parsedPort) || parsedPort <= 0 || parsedPort > 65535) {
    throw new Error('port must be a valid TCP port.');
  }
}

function buildSqlConfig(payload) {
  const timeoutInSeconds = clamp(
    Number.parseInt(String(payload.timeoutInSeconds || '15'), 10) || 15,
    5,
    120,
  );

  return {
    server: payload.host.trim(),
    port: Number.parseInt(String(payload.port), 10),
    database: payload.database.trim(),
    user: payload.username.trim(),
    password: payload.password,
    options: {
      encrypt: false,
      trustServerCertificate: true,
    },
    pool: {
      max: 10,
      min: 0,
      idleTimeoutMillis: 30_000,
    },
    connectionTimeout: timeoutInSeconds * 1000,
    requestTimeout: timeoutInSeconds * 1000,
  };
}

async function createPoolWithDatabaseBootstrap(payload) {
  const requestedDatabase = payload.database.trim();
  const primaryConfig = buildSqlConfig(payload);

  try {
    return await createPool(primaryConfig);
  } catch (primaryError) {
    if (requestedDatabase.toLowerCase() === 'master') {
      throw normalizeConnectionError(primaryError);
    }

    const masterConfig = buildSqlConfig({
      ...payload,
      database: 'master',
    });

    let masterPool;
    try {
      masterPool = await createPool(masterConfig);
      await ensureDatabaseExists(masterPool, requestedDatabase);
    } catch (fallbackError) {
      throw normalizeConnectionError(fallbackError);
    } finally {
      if (masterPool) {
        try {
          await masterPool.close();
        } catch (_) {
          // Ignore close failure on fallback pool.
        }
      }
    }

    try {
      return await createPool(primaryConfig);
    } catch (retryError) {
      throw normalizeConnectionError(retryError);
    }
  }
}

async function ensureDatabaseExists(pool, databaseName) {
  const escapedIdentifier = escapeSqlIdentifier(databaseName);
  const escapedLiteral = escapeSqlLiteral(databaseName);

  await pool.request().batch(`
IF DB_ID(N'${escapedLiteral}') IS NULL
BEGIN
  EXEC('CREATE DATABASE [${escapedIdentifier}]');
END;
`);
}

function normalizeConnectionError(error) {
  const rawMessage = String(error?.message || 'Unable to connect to SQL Server.');
  const lower = rawMessage.toLowerCase();

  if (lower.includes("login failed for user")) {
    return new Error(
      'Login failed for SQL user. Verify SQL host/port and the SA password (MSSQL_SA_PASSWORD).',
    );
  }

  if (lower.includes('cannot open database')) {
    return new Error(
      'Database is not accessible for this login. Verify database name or permissions.',
    );
  }

  if (lower.includes('failed to connect') || lower.includes('econnrefused')) {
    return new Error(
      'Could not reach SQL Server. Ensure Docker container is running and port 1433 is mapped.',
    );
  }

  return new Error(rawMessage);
}

function escapeSqlIdentifier(value) {
  return String(value).replace(/]/g, ']]');
}

function escapeSqlLiteral(value) {
  return String(value).replace(/'/g, "''");
}

async function createPool(config) {
  const pool = new sql.ConnectionPool(config);
  await pool.connect();
  return pool;
}

async function executeQuery(pool, queryText, params = {}) {
  const request = pool.request();
  for (const [key, value] of Object.entries(params)) {
    request.input(key, value ?? null);
  }
  return request.query(queryText);
}

async function nextMemberNumber(pool) {
  const result = await executeQuery(
    pool,
    `
SELECT
  ISNULL(MAX(TRY_CAST(SUBSTRING(MemberNumber, 5, 20) AS INT)), 0) AS LastSequence
FROM dbo.Members
WHERE MemberNumber LIKE 'PQR-%';
`,
  );

  const current = toInt(result.recordset?.[0]?.LastSequence);
  const next = current + 1;
  return `PQR-${String(next).padStart(5, '0')}`;
}

async function runSchema(pool) {
  const sqlPath = path.join(__dirname, '..', 'sql', 'pqr_cooperative_schema.sql');
  const script = await fs.readFile(sqlPath, 'utf8');
  const batches = splitSqlBatches(script);

  for (const batch of batches) {
    await pool.request().batch(batch);
  }

  return batches.length;
}

function splitSqlBatches(script) {
  const lines = script.split(/\r?\n/);
  const batches = [];
  let current = [];

  for (const line of lines) {
    if (line.trim().toUpperCase() === 'GO') {
      const batch = current.join('\n').trim();
      if (batch) {
        batches.push(batch);
      }
      current = [];
    } else {
      current.push(line);
    }
  }

  const tail = current.join('\n').trim();
  if (tail) {
    batches.push(tail);
  }

  return batches;
}

async function cleanupIdleSessions() {
  const now = Date.now();
  for (const [token, session] of sessions.entries()) {
    if (now - session.lastUsedAt > SESSION_IDLE_MS) {
      try {
        await session.pool.close();
      } catch (_) {
        // Best effort close.
      }
      sessions.delete(token);
    }
  }
}

async function closeAllSessions() {
  for (const [token, session] of sessions.entries()) {
    try {
      await session.pool.close();
    } catch (_) {
      // Ignore close errors on shutdown.
    }
    sessions.delete(token);
  }
}

function cleanString(value) {
  if (value == null) {
    return '';
  }
  return String(value).trim();
}

function toInt(value) {
  const parsed = Number.parseInt(String(value || '0'), 10);
  if (!Number.isFinite(parsed)) {
    return 0;
  }
  return parsed;
}

function toNumber(value) {
  const parsed = Number.parseFloat(String(value || '0'));
  if (!Number.isFinite(parsed)) {
    return 0;
  }
  return parsed;
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function dateOnly(value) {
  const year = value.getFullYear().toString().padStart(4, '0');
  const month = (value.getMonth() + 1).toString().padStart(2, '0');
  const day = value.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

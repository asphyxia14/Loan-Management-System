/*
PQR Cooperative - Member and Loan Management Schema

Run this script against your SQL Server instance.
If you use Docker SQL Server, connect via VS Code SQL Server extension and execute.
*/

IF DB_ID('PQRCooperative') IS NULL
BEGIN
  CREATE DATABASE PQRCooperative;
END;
GO

USE PQRCooperative;
GO

IF OBJECT_ID('dbo.Members', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Members (
    MemberId INT IDENTITY(1, 1) PRIMARY KEY,
    MemberNumber NVARCHAR(30) NOT NULL UNIQUE,
    FullName NVARCHAR(120) NOT NULL,
    PhoneNumber NVARCHAR(30) NULL,
    AddressLine NVARCHAR(250) NULL,
    JoinedDate DATE NOT NULL CONSTRAINT DF_Members_JoinedDate DEFAULT CAST(GETDATE() AS DATE),
    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Members_Status DEFAULT 'ACTIVE',
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Members_CreatedAt DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Members_UpdatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Members_Status CHECK (Status IN ('ACTIVE', 'INACTIVE'))
  );
END;
GO

IF OBJECT_ID('dbo.SavingsTransactions', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.SavingsTransactions (
    SavingsTransactionId BIGINT IDENTITY(1, 1) PRIMARY KEY,
    MemberId INT NOT NULL,
    TransactionDate DATE NOT NULL,
    TransactionType NVARCHAR(20) NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    ReferenceNo NVARCHAR(50) NULL,
    Remarks NVARCHAR(250) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_SavingsTransactions_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT FK_SavingsTransactions_Members FOREIGN KEY (MemberId)
      REFERENCES dbo.Members (MemberId),
    CONSTRAINT CK_SavingsTransactions_Type CHECK (TransactionType IN ('DEPOSIT', 'WITHDRAWAL')),
    CONSTRAINT CK_SavingsTransactions_Amount CHECK (Amount > 0)
  );
END;
GO

IF OBJECT_ID('dbo.LoanAccounts', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.LoanAccounts (
    LoanId INT IDENTITY(1, 1) PRIMARY KEY,
    MemberId INT NOT NULL,
    ApplicationDate DATE NOT NULL,
    ApprovalDate DATE NULL,
    PrincipalAmount DECIMAL(18, 2) NOT NULL,
    InterestRateAnnual DECIMAL(5, 2) NOT NULL,
    TermMonths INT NOT NULL,
    TotalInterestExpected DECIMAL(18, 2) NOT NULL,
    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_LoanAccounts_Status DEFAULT 'PENDING',
    Purpose NVARCHAR(250) NULL,
    ApprovedBy NVARCHAR(120) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_LoanAccounts_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT FK_LoanAccounts_Members FOREIGN KEY (MemberId)
      REFERENCES dbo.Members (MemberId),
    CONSTRAINT CK_LoanAccounts_Status CHECK (Status IN ('PENDING', 'APPROVED', 'REJECTED', 'CLOSED')),
    CONSTRAINT CK_LoanAccounts_Principal CHECK (PrincipalAmount > 0),
    CONSTRAINT CK_LoanAccounts_Interest CHECK (InterestRateAnnual >= 0),
    CONSTRAINT CK_LoanAccounts_Term CHECK (TermMonths > 0),
    CONSTRAINT CK_LoanAccounts_TotalInterest CHECK (TotalInterestExpected >= 0)
  );
END;
GO

IF OBJECT_ID('dbo.LoanPayments', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.LoanPayments (
    LoanPaymentId BIGINT IDENTITY(1, 1) PRIMARY KEY,
    LoanId INT NOT NULL,
    PaymentDate DATE NOT NULL,
    PrincipalPaid DECIMAL(18, 2) NOT NULL CONSTRAINT DF_LoanPayments_Principal DEFAULT 0,
    InterestPaid DECIMAL(18, 2) NOT NULL CONSTRAINT DF_LoanPayments_Interest DEFAULT 0,
    PenaltyPaid DECIMAL(18, 2) NOT NULL CONSTRAINT DF_LoanPayments_Penalty DEFAULT 0,
    Remarks NVARCHAR(250) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_LoanPayments_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT FK_LoanPayments_LoanAccounts FOREIGN KEY (LoanId)
      REFERENCES dbo.LoanAccounts (LoanId),
    CONSTRAINT CK_LoanPayments_Value CHECK (
      PrincipalPaid >= 0
      AND InterestPaid >= 0
      AND PenaltyPaid >= 0
      AND (PrincipalPaid + InterestPaid + PenaltyPaid) > 0
    )
  );
END;
GO

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'IX_SavingsTransactions_MemberDate'
    AND object_id = OBJECT_ID('dbo.SavingsTransactions')
)
BEGIN
  CREATE INDEX IX_SavingsTransactions_MemberDate
    ON dbo.SavingsTransactions(MemberId, TransactionDate DESC);
END;
GO

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'IX_LoanPayments_LoanDate'
    AND object_id = OBJECT_ID('dbo.LoanPayments')
)
BEGIN
  CREATE INDEX IX_LoanPayments_LoanDate
    ON dbo.LoanPayments(LoanId, PaymentDate DESC);
END;
GO

IF OBJECT_ID('dbo.trg_RejectNegativeSavingsBalance', 'TR') IS NOT NULL
BEGIN
  DROP TRIGGER dbo.trg_RejectNegativeSavingsBalance;
END;
GO

CREATE TRIGGER dbo.trg_RejectNegativeSavingsBalance
ON dbo.SavingsTransactions
FOR INSERT, UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (
    SELECT 1
    FROM (
      SELECT
        st.MemberId,
        SUM(CASE WHEN st.TransactionType = 'DEPOSIT' THEN st.Amount ELSE -st.Amount END) AS CurrentBalance
      FROM dbo.SavingsTransactions st
      WHERE st.MemberId IN (SELECT DISTINCT MemberId FROM inserted)
      GROUP BY st.MemberId
    ) balances
    WHERE balances.CurrentBalance < 0
  )
  BEGIN
    RAISERROR('Withdrawal exceeds available savings balance.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
  END
END;
GO

IF OBJECT_ID('dbo.vMemberSavingsBalance', 'V') IS NOT NULL
BEGIN
  DROP VIEW dbo.vMemberSavingsBalance;
END;
GO

CREATE VIEW dbo.vMemberSavingsBalance
AS
SELECT
  m.MemberId,
  CAST(
    ISNULL(
      SUM(
        CASE
          WHEN st.TransactionType = 'DEPOSIT' THEN st.Amount
          ELSE -st.Amount
        END
      ),
      0.00
    ) AS DECIMAL(18, 2)
  ) AS SavingsBalance
FROM dbo.Members m
LEFT JOIN dbo.SavingsTransactions st
  ON st.MemberId = m.MemberId
GROUP BY m.MemberId;
GO

IF OBJECT_ID('dbo.vLoanOutstanding', 'V') IS NOT NULL
BEGIN
  DROP VIEW dbo.vLoanOutstanding;
END;
GO

CREATE VIEW dbo.vLoanOutstanding
AS
SELECT
  la.LoanId,
  la.MemberId,
  m.MemberNumber,
  m.FullName AS MemberName,
  la.Status,
  la.PrincipalAmount,
  la.TotalInterestExpected,
  la.ApprovalDate,
  la.TermMonths,
  la.InterestRateAnnual,
  la.Purpose,
  CAST(ISNULL(p.PrincipalPaid, 0.00) AS DECIMAL(18, 2)) AS PrincipalPaid,
  CAST(ISNULL(p.InterestPaid, 0.00) AS DECIMAL(18, 2)) AS InterestPaid,
  CAST(ISNULL(p.PenaltyPaid, 0.00) AS DECIMAL(18, 2)) AS PenaltyPaid,
  CAST(
    CASE
      WHEN (la.PrincipalAmount + la.TotalInterestExpected - ISNULL(p.PrincipalPaid, 0.00) - ISNULL(p.InterestPaid, 0.00)) < 0
      THEN 0.00
      ELSE (la.PrincipalAmount + la.TotalInterestExpected - ISNULL(p.PrincipalPaid, 0.00) - ISNULL(p.InterestPaid, 0.00))
    END AS DECIMAL(18, 2)
  ) AS TotalOutstanding
FROM dbo.LoanAccounts la
INNER JOIN dbo.Members m
  ON m.MemberId = la.MemberId
OUTER APPLY (
  SELECT
    SUM(lp.PrincipalPaid) AS PrincipalPaid,
    SUM(lp.InterestPaid) AS InterestPaid,
    SUM(lp.PenaltyPaid) AS PenaltyPaid
  FROM dbo.LoanPayments lp
  WHERE lp.LoanId = la.LoanId
) p;
GO

IF OBJECT_ID('dbo.trg_CloseLoanWhenFullyPaid', 'TR') IS NOT NULL
BEGIN
  DROP TRIGGER dbo.trg_CloseLoanWhenFullyPaid;
END;
GO

CREATE TRIGGER dbo.trg_CloseLoanWhenFullyPaid
ON dbo.LoanPayments
FOR INSERT, UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH affected_loans AS (
    SELECT DISTINCT LoanId
    FROM inserted
  ),
  outstanding AS (
    SELECT
      v.LoanId,
      v.TotalOutstanding
    FROM dbo.vLoanOutstanding v
    INNER JOIN affected_loans al
      ON al.LoanId = v.LoanId
  )
  UPDATE la
    SET Status = CASE WHEN o.TotalOutstanding <= 0 THEN 'CLOSED' ELSE la.Status END
  FROM dbo.LoanAccounts la
  INNER JOIN outstanding o
    ON o.LoanId = la.LoanId
  WHERE la.Status IN ('APPROVED', 'CLOSED');
END;
GO

IF OBJECT_ID('dbo.vMonthlyFinancialSummary', 'V') IS NOT NULL
BEGIN
  DROP VIEW dbo.vMonthlyFinancialSummary;
END;
GO

CREATE VIEW dbo.vMonthlyFinancialSummary
AS
SELECT
  flow.ReportYear,
  flow.ReportMonth,
  CAST(SUM(flow.Deposits) AS DECIMAL(18, 2)) AS Deposits,
  CAST(SUM(flow.Withdrawals) AS DECIMAL(18, 2)) AS Withdrawals,
  CAST(SUM(flow.Deposits - flow.Withdrawals) AS DECIMAL(18, 2)) AS NetSavings,
  CAST(SUM(flow.LoanDisbursements) AS DECIMAL(18, 2)) AS LoanDisbursements,
  CAST(SUM(flow.LoanRepayments) AS DECIMAL(18, 2)) AS LoanRepayments,
  CAST(
    SUM(
      flow.Deposits
      - flow.Withdrawals
      - flow.LoanDisbursements
      + flow.LoanRepayments
    ) AS DECIMAL(18, 2)
  ) AS NetCashFlow
FROM (
  SELECT
    YEAR(st.TransactionDate) AS ReportYear,
    MONTH(st.TransactionDate) AS ReportMonth,
    CASE WHEN st.TransactionType = 'DEPOSIT' THEN st.Amount ELSE 0.00 END AS Deposits,
    CASE WHEN st.TransactionType = 'WITHDRAWAL' THEN st.Amount ELSE 0.00 END AS Withdrawals,
    0.00 AS LoanDisbursements,
    0.00 AS LoanRepayments
  FROM dbo.SavingsTransactions st

  UNION ALL

  SELECT
    YEAR(la.ApprovalDate) AS ReportYear,
    MONTH(la.ApprovalDate) AS ReportMonth,
    0.00 AS Deposits,
    0.00 AS Withdrawals,
    la.PrincipalAmount AS LoanDisbursements,
    0.00 AS LoanRepayments
  FROM dbo.LoanAccounts la
  WHERE la.Status IN ('APPROVED', 'CLOSED')
    AND la.ApprovalDate IS NOT NULL

  UNION ALL

  SELECT
    YEAR(lp.PaymentDate) AS ReportYear,
    MONTH(lp.PaymentDate) AS ReportMonth,
    0.00 AS Deposits,
    0.00 AS Withdrawals,
    0.00 AS LoanDisbursements,
    (lp.PrincipalPaid + lp.InterestPaid + lp.PenaltyPaid) AS LoanRepayments
  FROM dbo.LoanPayments lp
) flow
GROUP BY flow.ReportYear, flow.ReportMonth;
GO

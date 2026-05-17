<<<<<<< HEAD
# Loan-Management-System
Project for Finals
=======
# PQR Cooperative - Member and Loan Management

Flutter frontend with a local REST backend for MSSQL access.

This replaces direct `mssql_connection` usage so the app works across Flutter platforms (Android, iOS, desktop, and web), not just Android.

## What This Solves

The old process used paper forms, passbooks, and manual ledgers that caused duplicate entries and difficult reporting.

This app implements a new process with one SQL-backed ledger:

1. Every member is registered once with a unique member number.
2. Savings deposits and withdrawals are posted in a single transaction table.
3. Loan approval stores principal, interest terms, and expected totals in a consistent format.
4. Loan payments update balances through SQL views and close loans automatically when fully paid.
5. Monthly financial summaries are generated from SQL views instead of manual spreadsheet consolidation.

## Tech Stack

- Flutter frontend: [lib/main.dart](lib/main.dart)
- Dart HTTP client service: [lib/data/coop_database_service.dart](lib/data/coop_database_service.dart)
- Node.js REST backend: [backend/server.js](backend/server.js)
- MS SQL Server in Docker
- SQL schema script: [sql/pqr_cooperative_schema.sql](sql/pqr_cooperative_schema.sql)

## Database Design

Core tables:

- `Members`
- `SavingsTransactions`
- `LoanAccounts`
- `LoanPayments`

Controls to prevent old process errors:

- Unique member number (`MemberNumber`)
- Constraints for valid transaction and loan values
- Trigger that rejects withdrawals that would create negative savings balance
- Loan status trigger that auto-closes loans when fully settled

Automated reporting views:

- `vMemberSavingsBalance`
- `vLoanOutstanding`
- `vMonthlyFinancialSummary`

## Run MSSQL in Docker

Example command:

```bash
docker run -e "ACCEPT_EULA=Y" \
	-e "MSSQL_SA_PASSWORD=YourStrong!Passw0rd" \
	-p 1433:1433 \
	--name pqr-sql \
	-d mcr.microsoft.com/mssql/server:2022-latest
```

## Use VS Code SQL Server Extension

1. Connect to `localhost` on port `1433` using user `sa` and your password.
2. Create database `PQRCooperative` or run the script below.
3. Execute `sql/pqr_cooperative_schema.sql` from the extension query editor.

## Run Backend API

```bash
cd backend
npm install
npm start
```

Default API URL is `http://127.0.0.1:8080`.

The backend creates a SQL session token from the credentials you provide in the Flutter app and executes all SQL operations server-side.

## Run Flutter App

```bash
flutter pub get
flutter run
```

In the app connection screen:

- Backend API URL: `http://127.0.0.1:8080` (desktop)
- Backend API URL: `http://10.0.2.2:8080` (Android emulator)
- SQL Host: `127.0.0.1`
- SQL Port: `1433`
- SQL Database: `PQRCooperative`
- SQL Username: `sa`
- SQL Password: your SA password

Then click `Connect and Initialize Schema`.

This calls backend endpoints to:

1. Open and validate SQL connection.
2. Initialize/update schema from `sql/pqr_cooperative_schema.sql`.
3. Run all member, savings, loan, and report operations via HTTP.

## Why This Approach

- Avoids platform limitation of direct MSSQL Flutter plugins.
- Keeps SQL credentials and query execution in backend layer.
- Easier to evolve into production architecture (auth, auditing, role control, API hardening).

## Notes

- This project uses an in-memory backend session map for development convenience.
- For production: use persistent auth/session storage, HTTPS, and secret management.
>>>>>>> 4a6df40 (Initial commit.)

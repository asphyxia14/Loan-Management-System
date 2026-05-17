# How the System Works

This project uses three main parts that work together:

1. Flutter app - the user interface.
2. Node.js backend - the middle layer.
3. MSSQL database - the data storage.

## 1. Flutter App

The Flutter app is what the user sees and interacts with. It contains the screens for:

- connecting to the system
- managing members
- posting savings transactions
- creating loans
- recording loan payments
- generating reports

The Flutter app does not talk directly to the SQL Server database. Instead, it sends HTTP requests to the Node.js backend.

## 2. What Node.js Does

Node.js acts as the server-side application in this system.

Its job is to:

- receive requests from the Flutter app
- validate the input before it reaches the database
- connect securely to MSSQL
- run SQL queries and commands
- return results back to Flutter as JSON
- enforce business rules that should not depend only on the user interface

In simple terms, Node.js is the bridge between Flutter and the database.

### Why Node.js is needed

Flutter is a client app, so it should not connect directly to MSSQL in this project. Using Node.js makes the system work across desktop, Android, iOS, and web because the database logic stays on the server side.

Node.js also gives better control over security and business rules. For example:

- it can reject invalid savings transactions
- it can prevent deleting members that already have financial records
- it can block loan payments that are larger than the outstanding balance
- it can check whether a member is active before allowing transactions

## 3. MSSQL Database

MSSQL stores the actual cooperative data.

The database keeps records for:

- members
- savings transactions
- loan accounts
- loan payments

It also includes views and triggers that help enforce rules and generate summaries.

## 4. Typical Flow of Data

When the user performs an action in the app, the flow is usually like this:

1. The user enters data in Flutter.
2. Flutter sends the data to Node.js using an HTTP request.
3. Node.js checks whether the data is valid.
4. Node.js runs the SQL command in MSSQL.
5. MSSQL stores or reads the data.
6. Node.js sends the result back to Flutter.
7. Flutter updates the screen.

## 5. Example: Adding a Member

For example, when a user adds a new member:

1. The user fills in the member form in Flutter.
2. Flutter sends the form data to the backend.
3. Node.js checks that the member name is not empty.
4. Node.js inserts the new member into the Members table.
5. The database returns the new member ID.
6. Flutter refreshes the member list.

## 6. Example: Posting a Savings Transaction

When the user posts a savings transaction:

1. Flutter sends the member ID, amount, and transaction type to Node.js.
2. Node.js checks that the member is active.
3. Node.js stores the transaction in the savings table.
4. The database trigger and views keep balances accurate.
5. Flutter reloads the member balance and transaction history.

## 7. Example: Creating a Loan

When a loan is created:

1. Flutter sends the loan details to Node.js.
2. Node.js checks that the member is active and that the values are valid.
3. Node.js calculates the expected interest.
4. Node.js inserts the loan into MSSQL.
5. Flutter refreshes the loan list.

## 8. Example: Recording a Loan Payment

When a payment is posted:

1. Flutter sends the payment details to Node.js.
2. Node.js verifies that the loan is approved.
3. Node.js checks that the payment does not exceed the outstanding balance.
4. Node.js saves the payment in MSSQL.
5. The database updates the loan status when it becomes fully paid.

## 9. Why This Design Is Better

This structure is better than connecting Flutter directly to the database because it:

- works on more platforms
- keeps the database hidden from the client app
- allows reusable validation rules
- makes the system easier to maintain
- supports cleaner reporting and future improvements

## 10. Short Explanation You Can Say

If you need a very short explanation for class or defense, you can say:

"Flutter is the front end, Node.js is the middle layer that handles validation and database requests, and MSSQL is where all cooperative records are stored. Node.js connects the app to the database, checks the data, and returns the result back to the app."

# Chapter 1: Introduction

## 1.1 Background of Company

PQR Cooperative is a member-centered financial organization that provides basic cooperative services such as membership management, savings collection, and loan assistance. Its primary mission is to support the financial growth and stability of its members by offering accessible lending and encouraging a culture of savings. As the cooperative continues to grow, the volume of daily transactions and records has also increased, requiring more reliable methods of data handling and reporting.

Traditionally, many community cooperatives begin with manual and paper-based operations because they are simple to start and inexpensive at an early stage. However, as membership and transaction frequency increase, manual workflows become difficult to maintain. PQR Cooperative now needs a more structured and centralized information system that can support accurate records, faster transactions, and timely reporting for management decision-making.

## 1.2 Current System

The current system of PQR Cooperative is primarily manual and partially spreadsheet-based. Member registration details are written on paper forms and encoded separately. Savings deposits and withdrawals are tracked through manual ledgers and passbook entries. Loan applications are processed using printed forms, and loan balances are calculated using manual computation or basic spreadsheet formulas.

Monthly summaries are prepared by compiling records from different sources, which often includes physical logbooks, individual worksheets, and scattered digital files. This process depends heavily on staff availability and individual familiarity with records. Because there is no single centralized database connected to all cooperative operations, updates are not always synchronized and report generation takes significant time.

## 1.3 Problems of the Current System

The existing process presents several operational and data management issues:

1. Duplicate and inconsistent member records: Member information is filed using paper-based forms, causing data loss, duplication, and inconsistency when encoded in multiple places or updated in one file but not in others.

2. Slow transaction processing: Manual verification and encoding increase service time for savings deposits, withdrawals, and loan payments, delaying member service.

3. Computation errors and weak audit trail: Loan interest, outstanding balances, and monthly totals are prone to human error. It is difficult to trace who made a change and when a transaction was posted.

4. Delayed reporting: Management reports require manual consolidation from different sources and are not available in real time.

5. Data security and continuity risks: Paper documents and scattered spreadsheets are vulnerable to loss, damage, and unauthorized access.

These issues reduce operational efficiency, affect data reliability, and limit the cooperative's ability to make timely and **evidence**-based decisions.

## 1.4 Objectives of the System

### General Objective

To design and implement an integrated Cooperative Management Information System for PQR Cooperative that centralizes member, savings, loan, payment, and reporting processes in one reliable platform.

### Specific Objectives

1. To digitize member registration and enforce a unique member profile for each cooperative member, preventing duplicate and inconsistent records.

2. To record savings transactions in a centralized ledger with validation rules to prevent invalid postings and enable real-time balance updates.

3. To standardize loan creation by capturing principal, interest rate, term, and approval details consistently to reduce computation errors and to automate loan payment posting and update outstanding balances accurately, with traceable audit records for accountability.

4. To generate monthly financial summaries automatically for faster, timely, and accurate decision support.

5. To improve data accessibility, transparency, and operational efficiency for authorized cooperative staff, replacing manual encoding with digital workflows.

## 1.5 Scope and Limitation of the System

### Scope

The proposed system covers the core internal operations of PQR Cooperative through the following functional modules:

1. **Members Tab**: Member registration, profile management, and member status tracking.

2. **Savings Tab**: Savings deposit and withdrawal recording with real-time balance tracking.

3. **Loans Tab**: Loan account creation, approval tracking, loan balance monitoring, and loan payment posting with outstanding balance updates.

4. **Dashboard Tab**: Monthly financial summary generation and operational reporting.

5. **Backend Infrastructure**: Centralized data storage using MSSQL and Node.js REST API for secure server-side processing and validation.

The system is intended for office use by authorized cooperative personnel and is designed to support desktop-focused workflows.

### Limitations

The system does not currently include the following, and here is why:

1. **Online member self-service portal**: Managing member login, account access, and self-service infrastructure is outside the current scope. This would be addressed in future phases as the organization expands digital accessibility and member engagement channels.

2. **Mobile wallet, banking, or payment gateway integration**: External payment integrations require coordination with third-party vendors and additional security compliance. These are deferred to later versions when the organization is ready to expand beyond internal office operations.

3. **SMS or email notification services**: Notification infrastructure requires email/SMS gateways and template management. The current system relies on staff to inform members of important notices. This feature can be added once notification channels are established and governance policies are in place.

4. **Advanced multi-branch management and enterprise-level analytics**: The current version is designed for single-location operations. Multi-branch support requires additional data modeling, branch-specific reporting, and role-based access control, planned for future expansion as the cooperative grows.

5. **Fully hardened production-grade security infrastructure**: The current deployment is suitable for pilot and small-scale operations. Production-grade security (SSL/TLS certificates, advanced access controls, comprehensive backup and disaster recovery) will be implemented as the system scales and as budget allows.

These limitations define the boundaries of the current project and identify areas for future enhancement as PQR Cooperative grows and operational requirements evolve.

## 1.6 Significance of the System

The proposed system is significant because it provides practical benefits to multiple stakeholders:

1. **Cooperative Management**: Enables faster access to accurate financial and operational reports for planning and policy decisions. With automated reporting, management can analyze trends, monitor member engagement, and make evidence-based strategic decisions without delays.

2. **Staff and Operators**: Reduces manual workload, minimizes repetitive encoding, and improves day-to-day transaction efficiency. Staff can focus on member service rather than data entry.

3. **Members**: Promotes transparency and confidence through more accurate handling of savings and loan records.

4. **Organization as a Whole**: Strengthens internal control, record integrity, and continuity of operations.

5. **Future Researchers and Developers**: Serves as a foundation for further enhancements such as analytics, notifications, and member self-service modules.

By replacing fragmented manual procedures with a centralized digital process, PQR Cooperative can improve service quality, reduce errors, and build a stronger operational framework for long-term growth.

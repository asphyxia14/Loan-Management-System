class DbConnectionConfig {
  const DbConnectionConfig({
    required this.apiBaseUrl,
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.timeoutInSeconds = 15,
  });

  final String apiBaseUrl;
  final String host;
  final String port;
  final String database;
  final String username;
  final String password;
  final int timeoutInSeconds;
}

class MemberRecord {
  const MemberRecord({
    required this.memberId,
    required this.memberNumber,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine,
    required this.joinedDate,
    required this.status,
    required this.savingsBalance,
  });

  final int memberId;
  final String memberNumber;
  final String fullName;
  final String phoneNumber;
  final String addressLine;
  final DateTime joinedDate;
  final String status;
  final double savingsBalance;

  factory MemberRecord.fromRow(Map<String, dynamic> row) {
    return MemberRecord(
      memberId: _toInt(row['MemberId']),
      memberNumber: _toStringValue(row['MemberNumber']),
      fullName: _toStringValue(row['FullName']),
      phoneNumber: _toStringValue(row['PhoneNumber']),
      addressLine: _toStringValue(row['AddressLine']),
      joinedDate: _toDateTime(row['JoinedDate']) ?? DateTime.now(),
      status: _toStringValue(row['Status']),
      savingsBalance: _toDouble(row['SavingsBalance']),
    );
  }
}

class SavingsTransactionRecord {
  const SavingsTransactionRecord({
    required this.savingsTransactionId,
    required this.memberId,
    required this.transactionDate,
    required this.transactionType,
    required this.amount,
    required this.referenceNo,
    required this.remarks,
  });

  final int savingsTransactionId;
  final int memberId;
  final DateTime transactionDate;
  final String transactionType;
  final double amount;
  final String referenceNo;
  final String remarks;

  factory SavingsTransactionRecord.fromRow(Map<String, dynamic> row) {
    return SavingsTransactionRecord(
      savingsTransactionId: _toInt(row['SavingsTransactionId']),
      memberId: _toInt(row['MemberId']),
      transactionDate: _toDateTime(row['TransactionDate']) ?? DateTime.now(),
      transactionType: _toStringValue(row['TransactionType']),
      amount: _toDouble(row['Amount']),
      referenceNo: _toStringValue(row['ReferenceNo']),
      remarks: _toStringValue(row['Remarks']),
    );
  }
}

class LoanAccountRecord {
  const LoanAccountRecord({
    required this.loanId,
    required this.memberId,
    required this.memberNumber,
    required this.memberName,
    required this.status,
    required this.principalAmount,
    required this.totalInterestExpected,
    required this.totalOutstanding,
    required this.approvalDate,
    required this.termMonths,
    required this.interestRateAnnual,
    required this.purpose,
    required this.totalPaid,
    required this.loanSummary,
  });

  final int loanId;
  final int memberId;
  final String memberNumber;
  final String memberName;
  final String status;
  final double principalAmount;
  final double totalInterestExpected;
  final double totalOutstanding;
  final DateTime? approvalDate;
  final int termMonths;
  final double interestRateAnnual;
  final String purpose;
  final double totalPaid;
  final String loanSummary;

  factory LoanAccountRecord.fromRow(Map<String, dynamic> row) {
    return LoanAccountRecord(
      loanId: _toInt(row['LoanId']),
      memberId: _toInt(row['MemberId']),
      memberNumber: _toStringValue(row['MemberNumber']),
      memberName: _toStringValue(row['MemberName']),
      status: _toStringValue(row['Status']),
      principalAmount: _toDouble(row['PrincipalAmount']),
      totalInterestExpected: _toDouble(row['TotalInterestExpected']),
      totalOutstanding: _toDouble(row['TotalOutstanding']),
      approvalDate: _toDateTime(row['ApprovalDate']),
      termMonths: _toInt(row['TermMonths']),
      interestRateAnnual: _toDouble(row['InterestRateAnnual']),
      purpose: _toStringValue(row['Purpose']),
      totalPaid: _toDouble(row['TotalPaid']),
      loanSummary: _toStringValue(row['LoanSummary']),
    );
  }
}

class LoanPaymentRecord {
  const LoanPaymentRecord({
    required this.loanPaymentId,
    required this.loanId,
    required this.paymentDate,
    required this.principalPaid,
    required this.interestPaid,
    required this.penaltyPaid,
    required this.remarks,
  });

  final int loanPaymentId;
  final int loanId;
  final DateTime paymentDate;
  final double principalPaid;
  final double interestPaid;
  final double penaltyPaid;
  final String remarks;

  factory LoanPaymentRecord.fromRow(Map<String, dynamic> row) {
    return LoanPaymentRecord(
      loanPaymentId: _toInt(row['LoanPaymentId']),
      loanId: _toInt(row['LoanId']),
      paymentDate: _toDateTime(row['PaymentDate']) ?? DateTime.now(),
      principalPaid: _toDouble(row['PrincipalPaid']),
      interestPaid: _toDouble(row['InterestPaid']),
      penaltyPaid: _toDouble(row['PenaltyPaid']),
      remarks: _toStringValue(row['Remarks']),
    );
  }
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.activeMembers,
    required this.totalSavings,
    required this.activeLoans,
    required this.totalLoanOutstanding,
  });

  final int activeMembers;
  final double totalSavings;
  final int activeLoans;
  final double totalLoanOutstanding;
}

class MonthlyFinancialSummary {
  const MonthlyFinancialSummary({
    required this.year,
    required this.month,
    required this.deposits,
    required this.withdrawals,
    required this.netSavings,
    required this.loanDisbursements,
    required this.loanRepayments,
    required this.netCashFlow,
  });

  final int year;
  final int month;
  final double deposits;
  final double withdrawals;
  final double netSavings;
  final double loanDisbursements;
  final double loanRepayments;
  final double netCashFlow;

  factory MonthlyFinancialSummary.fromRow(Map<String, dynamic> row) {
    return MonthlyFinancialSummary(
      year: _toInt(row['ReportYear']),
      month: _toInt(row['ReportMonth']),
      deposits: _toDouble(row['Deposits']),
      withdrawals: _toDouble(row['Withdrawals']),
      netSavings: _toDouble(row['NetSavings']),
      loanDisbursements: _toDouble(row['LoanDisbursements']),
      loanRepayments: _toDouble(row['LoanRepayments']),
      netCashFlow: _toDouble(row['NetCashFlow']),
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String _toStringValue(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

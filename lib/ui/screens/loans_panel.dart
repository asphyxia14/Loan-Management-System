import 'package:flutter/cupertino.dart';

import '../../models/app_models.dart';
import '../widgets/app_section_card.dart';

class LoansPanel extends StatelessWidget {
  const LoansPanel({
    super.key,
    required this.members,
    required this.loans,
    required this.selectedLoanMemberId,
    required this.selectedPaymentLoanId,
    required this.loanPrincipalController,
    required this.loanRateController,
    required this.loanTermMonthsController,
    required this.loanPurposeController,
    required this.loanApprovedByController,
    required this.paymentPrincipalController,
    required this.paymentInterestController,
    required this.paymentPenaltyController,
    required this.paymentRemarksController,
    required this.paymentHistory,
    required this.onSelectLoanMember,
    required this.onCreateLoan,
    required this.onSelectPaymentLoan,
    required this.onPostPayment,
    required this.formatMoney,
    required this.formatDate,
  });

  final List<MemberRecord> members;
  final List<LoanAccountRecord> loans;
  final int? selectedLoanMemberId;
  final int? selectedPaymentLoanId;

  final TextEditingController loanPrincipalController;
  final TextEditingController loanRateController;
  final TextEditingController loanTermMonthsController;
  final TextEditingController loanPurposeController;
  final TextEditingController loanApprovedByController;

  final TextEditingController paymentPrincipalController;
  final TextEditingController paymentInterestController;
  final TextEditingController paymentPenaltyController;
  final TextEditingController paymentRemarksController;

  final List<LoanPaymentRecord> paymentHistory;

  final ValueChanged<int?> onSelectLoanMember;
  final VoidCallback onCreateLoan;
  final ValueChanged<int?> onSelectPaymentLoan;
  final VoidCallback onPostPayment;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;

  Widget _field(
    TextEditingController controller,
    String placeholder, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.separator),
      ),
    );
  }

  Widget _selectorTile(String label, String value, VoidCallback onTap) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.separator),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '$label: $value',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: CupertinoColors.label),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: CupertinoColors.secondaryLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableCell(String text, {double? width, bool header = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: header
              ? CupertinoColors.secondaryLabel
              : CupertinoColors.label,
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
          fontSize: header ? 12 : 14,
        ),
      ),
    );
  }

  Future<void> _pickLoanMember(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select Member'),
          actions: members
              .map((MemberRecord member) {
                return CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSelectLoanMember(member.memberId);
                  },
                  child: Text('${member.memberNumber} - ${member.fullName}'),
                );
              })
              .toList(growable: false),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _pickPaymentLoan(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select Loan'),
          actions: loans
              .map((LoanAccountRecord loan) {
                return CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSelectPaymentLoan(loan.loanId);
                  },
                  child: Text(
                    'Loan ${loan.loanId} - ${loan.memberName} - ${formatMoney(loan.totalOutstanding)}',
                  ),
                );
              })
              .toList(growable: false),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    MemberRecord? selectedLoanMember;
    for (final MemberRecord member in members) {
      if (member.memberId == selectedLoanMemberId) {
        selectedLoanMember = member;
        break;
      }
    }

    LoanAccountRecord? selectedPaymentLoan;
    for (final LoanAccountRecord loan in loans) {
      if (loan.loanId == selectedPaymentLoanId) {
        selectedPaymentLoan = loan;
        break;
      }
    }

    final Widget createLoanCard = AppSectionCard(
      title: 'Create and Approve Loan',
      icon: CupertinoIcons.creditcard_fill,
      child: members.isEmpty
          ? const Text('Add a member first before creating loans.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _selectorTile(
                  'Member',
                  selectedLoanMember == null
                      ? 'Select member'
                      : '${selectedLoanMember.memberNumber} - ${selectedLoanMember.fullName}',
                  () => _pickLoanMember(context),
                ),
                const SizedBox(height: 12),
                _field(
                  loanPrincipalController,
                  'Principal Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  loanRateController,
                  'Annual Interest Rate (%)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  loanTermMonthsController,
                  'Term (Months)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _field(loanPurposeController, 'Purpose'),
                const SizedBox(height: 12),
                _field(loanApprovedByController, 'Approved By'),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.topLeft,
                  child: CupertinoButton.filled(
                    onPressed: onCreateLoan,
                    child: const Text('Create Loan'),
                  ),
                ),
              ],
            ),
    );

    final Widget paymentCard = AppSectionCard(
      title: 'Record Loan Payment',
      icon: CupertinoIcons.money_dollar_circle_fill,
      child: loans.isEmpty
          ? const Text('No loans available yet.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _selectorTile(
                  'Loan',
                  selectedPaymentLoan == null
                      ? 'Select loan'
                      : 'Loan ${selectedPaymentLoan.loanId} - ${selectedPaymentLoan.memberName}',
                  () => _pickPaymentLoan(context),
                ),
                const SizedBox(height: 12),
                _field(
                  paymentPrincipalController,
                  'Principal Paid',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  paymentInterestController,
                  'Interest Paid',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  paymentPenaltyController,
                  'Penalty Paid',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _field(paymentRemarksController, 'Remarks'),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.topLeft,
                  child: CupertinoButton.filled(
                    onPressed: onPostPayment,
                    child: const Text('Post Payment'),
                  ),
                ),
              ],
            ),
    );

    final Widget accountsCard = AppSectionCard(
      title: 'Loan Accounts',
      subtitle: '${loans.length} loan account(s)',
      icon: CupertinoIcons.doc_text,
      child: loans.isEmpty
          ? const Text('No loan records yet.')
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: loans
                        .map((LoanAccountRecord loan) =>
                            _LoanAccountSummaryCard(
                              loan: loan,
                              formatMoney: formatMoney,
                            ))
                        .toList(growable: false),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: <Widget>[
                            _tableCell('Loan ID', width: 70, header: true),
                            _tableCell('Member', width: 150, header: true),
                            _tableCell('Status', width: 90, header: true),
                            _tableCell('Principal', width: 100, header: true),
                            _tableCell('Interest', width: 100, header: true),
                            _tableCell('Outstanding', width: 110, header: true),
                            _tableCell('Purpose', width: 150, header: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...loans.map((LoanAccountRecord loan) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.secondarySystemGroupedBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: <Widget>[
                              _tableCell(loan.loanId.toString(), width: 70),
                              _tableCell(loan.memberName, width: 150),
                              _tableCell(loan.status, width: 90),
                              _tableCell(
                                formatMoney(loan.principalAmount),
                                width: 100,
                              ),
                              _tableCell(
                                formatMoney(loan.totalInterestExpected),
                                width: 100,
                              ),
                              _tableCell(
                                formatMoney(loan.totalOutstanding),
                                width: 110,
                              ),
                              _tableCell(
                                loan.purpose.isEmpty ? '-' : loan.purpose,
                                width: 150,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );

    final Widget historyCard = AppSectionCard(
      title: 'Loan Payment History',
      icon: CupertinoIcons.clock,
      child: paymentHistory.isEmpty
          ? const Text('No payments yet for selected loan.')
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: paymentHistory
                        .map((LoanPaymentRecord row) =>
                            _LoanHistorySummaryCard(
                              row: row,
                              formatMoney: formatMoney,
                              formatDate: formatDate,
                            ))
                        .toList(growable: false),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: <Widget>[
                            _tableCell('Date', width: 100, header: true),
                            _tableCell('Principal', width: 100, header: true),
                            _tableCell('Interest', width: 100, header: true),
                            _tableCell('Penalty', width: 100, header: true),
                            _tableCell('Remarks', width: 150, header: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...paymentHistory.map((LoanPaymentRecord row) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.secondarySystemGroupedBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: <Widget>[
                              _tableCell(formatDate(row.paymentDate), width: 100),
                              _tableCell(
                                formatMoney(row.principalPaid),
                                width: 100,
                              ),
                              _tableCell(formatMoney(row.interestPaid), width: 100),
                              _tableCell(formatMoney(row.penaltyPaid), width: 100),
                              _tableCell(
                                row.remarks.isEmpty ? '-' : row.remarks,
                                width: 150,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useTwoColumns = constraints.maxWidth >= 1000;

          final Widget inputColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              createLoanCard,
              const SizedBox(height: 16),
              paymentCard,
            ],
          );

          final Widget dataColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              accountsCard,
              const SizedBox(height: 16),
              historyCard,
            ],
          );

          if (useTwoColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 2, child: inputColumn),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: dataColumn),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              inputColumn,
              const SizedBox(height: 16),
              dataColumn,
            ],
          );
        },
      ),
    );
  }
}

class _LoanAccountSummaryCard extends StatefulWidget {
  const _LoanAccountSummaryCard({
    required this.loan,
    required this.formatMoney,
  });

  final LoanAccountRecord loan;
  final String Function(double) formatMoney;

  @override
  State<_LoanAccountSummaryCard> createState() => _LoanAccountSummaryCardState();
}

class _LoanAccountSummaryCardState extends State<_LoanAccountSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CupertinoButton(
            padding: const EdgeInsets.all(12),
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Loan ${widget.loan.loanId} - ${widget.loan.memberName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.loan.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.label,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Bal: ${widget.formatMoney(widget.loan.totalOutstanding)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  color: CupertinoColors.secondaryLabel,
                  size: 16,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(height: 1, color: CupertinoColors.separator),
                  const SizedBox(height: 8),
                  Text('Principal: ${widget.formatMoney(widget.loan.principalAmount)}', style: const TextStyle(fontSize: 13, color: CupertinoColors.label)),
                  const SizedBox(height: 4),
                  Text('Interest: ${widget.formatMoney(widget.loan.totalInterestExpected)}', style: const TextStyle(fontSize: 13, color: CupertinoColors.label)),
                  const SizedBox(height: 4),
                  Text('Purpose: ${widget.loan.purpose.isEmpty ? '-' : widget.loan.purpose}', style: const TextStyle(fontSize: 13, color: CupertinoColors.label)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanHistorySummaryCard extends StatefulWidget {
  const _LoanHistorySummaryCard({
    required this.row,
    required this.formatMoney,
    required this.formatDate,
  });

  final LoanPaymentRecord row;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;

  @override
  State<_LoanHistorySummaryCard> createState() => _LoanHistorySummaryCardState();
}

class _LoanHistorySummaryCardState extends State<_LoanHistorySummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CupertinoButton(
            padding: const EdgeInsets.all(12),
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.formatDate(widget.row.paymentDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Prin: ${widget.formatMoney(widget.row.principalPaid)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Int: ${widget.formatMoney(widget.row.interestPaid)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  color: CupertinoColors.secondaryLabel,
                  size: 16,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(height: 1, color: CupertinoColors.separator),
                  const SizedBox(height: 8),
                  Text('Penalty: ${widget.formatMoney(widget.row.penaltyPaid)}', style: const TextStyle(fontSize: 13, color: CupertinoColors.label)),
                  const SizedBox(height: 4),
                  Text('Remarks: ${widget.row.remarks.isEmpty ? '-' : widget.row.remarks}', style: const TextStyle(fontSize: 13, color: CupertinoColors.label)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


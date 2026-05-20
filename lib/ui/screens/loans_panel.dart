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
    required this.onSearchChanged,
    required this.loanSearchController,
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
  final ValueChanged<String> onSearchChanged;
  final TextEditingController loanSearchController;
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
    String label,
    TextEditingController controller,
    String placeholder, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectorTile(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemGrey4.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CupertinoColors.label,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, {double? width}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          color: CupertinoColors.secondaryLabel,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _pickLoanMember(BuildContext context) async {
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 500),
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Member',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (BuildContext context, int index) {
                      final MemberRecord member = members[index];
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSelectLoanMember(member.memberId);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: CupertinoColors.separator),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${member.memberNumber} - ${member.fullName}',
                                  style: const TextStyle(
                                    color: CupertinoColors.label,
                                  ),
                                ),
                              ),
                              if (member.memberId == selectedLoanMemberId)
                                const Icon(
                                  CupertinoIcons.check_mark,
                                  size: 16,
                                  color: CupertinoColors.activeBlue,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPaymentLoan(BuildContext context) async {
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 500),
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Loan Account',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: loans.length,
                    itemBuilder: (BuildContext context, int index) {
                      final LoanAccountRecord loan = loans[index];
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSelectPaymentLoan(loan.loanId);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: CupertinoColors.separator),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  loan.loanSummary,
                                  style: const TextStyle(
                                    color: CupertinoColors.label,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (loan.loanId == selectedPaymentLoanId)
                                const Icon(
                                  CupertinoIcons.check_mark,
                                  size: 16,
                                  color: CupertinoColors.activeBlue,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String selectedMemberName = selectedLoanMemberId == null
        ? 'None'
        : (members
                .where((MemberRecord m) => m.memberId == selectedLoanMemberId)
                .firstOrNull
                ?.fullName ??
            'Unknown');

    final LoanAccountRecord? selectedLoan = selectedPaymentLoanId == null
        ? null
        : (loans
                .where((LoanAccountRecord l) =>
                    l.loanId == selectedPaymentLoanId)
                .firstOrNull);

    final String selectedPaymentName = selectedLoan == null
        ? 'None'
        : '[${selectedLoan.memberNumber}] ${selectedLoan.memberName}';

    final Widget createLoanCard = AppSectionCard(
      title: 'New Loan Application',
      icon: CupertinoIcons.doc_append,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _selectorTile(
            'Borrower',
            selectedMemberName,
            () => _pickLoanMember(context),
          ),
          const SizedBox(height: 16),
          _field(
            'PRINCIPAL AMOUNT',
            loanPrincipalController,
            'Enter principal',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  'INT. RATE %',
                  loanRateController,
                  'Enter rate',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'TERM (MONTHS)',
                  loanTermMonthsController,
                  'Enter term',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _field('PURPOSE', loanPurposeController, 'Enter purpose'),
          const SizedBox(height: 16),
          _field('APPROVED BY', loanApprovedByController, 'Enter approver name'),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.topLeft,
            child: CupertinoButton.filled(
              onPressed: onCreateLoan,
              child: const Text('Disburse Loan'),
            ),
          ),
        ],
      ),
    );

    final Widget postPaymentCard = AppSectionCard(
      title: 'Post Loan Payment',
      icon: CupertinoIcons.money_dollar_circle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _selectorTile(
            'Loan account',
            selectedPaymentName,
            () => _pickPaymentLoan(context),
          ),
          if (selectedLoan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL PAID',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatMoney(selectedLoan.totalPaid),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.systemGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: CupertinoColors.separator,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OUTSTANDING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatMoney(selectedLoan.totalOutstanding),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 4,
                      child: Row(
                        children: [
                          Expanded(
                            flex: ((selectedLoan.totalPaid) * 100).toInt().clamp(1, 999999999),
                            child: Container(color: CupertinoColors.systemGreen),
                          ),
                          Expanded(
                            flex: ((selectedLoan.totalOutstanding) * 100).toInt().clamp(1, 999999999),
                            child: Container(color: CupertinoColors.systemRed.withValues(alpha: 0.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  'PRINCIPAL PAID',
                  paymentPrincipalController,
                  'Enter principal amount',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'INTEREST PAID',
                  paymentInterestController,
                  'Enter interest amount',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _field(
            'PENALTY PAID',
            paymentPenaltyController,
            'Enter penalty amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          _field('REMARKS', paymentRemarksController, 'Enter remarks'),
          const SizedBox(height: 24),
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

    final Widget registryCard = AppSectionCard(
      title: 'Loan Registry',
      icon: CupertinoIcons.briefcase,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CupertinoSearchTextField(
              controller: loanSearchController,
              onChanged: onSearchChanged,
              placeholder: 'Search borrower or loan ID...',
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          loans.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No active loans found.'),
                )
              : SingleChildScrollView(
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
                            _headerCell('Loan ID', width: 70),
                            _headerCell('Borrower', width: 160),
                            _headerCell('Principal', width: 100),
                            _headerCell('Oustanding', width: 100),
                            _headerCell('Term', width: 80),
                            _headerCell('Status', width: 90),
                            _headerCell('Purpose', width: 150),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List<Widget>.generate(loans.length, (int index) {
                        final LoanAccountRecord loan = loans[index];
                        return _LoanTableRow(
                          loan: loan,
                          index: index,
                          formatMoney: formatMoney,
                        );
                      }),
                    ],
                  ),
                ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxWidth >= 1000) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: createLoanCard),
                    const SizedBox(width: 16),
                    Expanded(child: postPaymentCard),
                  ],
                );
              }
              return Column(
                children: <Widget>[
                  createLoanCard,
                  const SizedBox(height: 16),
                  postPaymentCard,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          registryCard,
        ],
      ),
    );
  }
}

class _LoanTableRow extends StatefulWidget {
  const _LoanTableRow({
    required this.loan,
    required this.index,
    required this.formatMoney,
  });

  final LoanAccountRecord loan;
  final int index;
  final String Function(double) formatMoney;

  @override
  State<_LoanTableRow> createState() => _LoanTableRowState();
}

class _LoanTableRowState extends State<_LoanTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isApproved = widget.loan.status.toUpperCase() == 'APPROVED';
    final bool isEven = widget.index % 2 == 0;

    Color backgroundColor = isEven
        ? CupertinoColors.secondarySystemGroupedBackground
        : CupertinoColors.systemGrey6.withValues(alpha: 0.3);
    
    if (_isHovered) {
      backgroundColor = CupertinoColors.activeBlue.withValues(alpha: 0.1);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            _tableCell('${widget.loan.loanId}', width: 70),
            _tableCell(widget.loan.memberName, width: 160, bold: true),
            _tableCell(widget.formatMoney(widget.loan.principalAmount), width: 100),
            _tableCell(
              widget.formatMoney(widget.loan.totalOutstanding),
              width: 100,
              bold: true,
              color: CupertinoColors.systemRed,
            ),
            _tableCell('${widget.loan.termMonths} mo', width: 80),
            SizedBox(
              width: 90,
              child: Text(
                widget.loan.status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isApproved ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                ),
              ),
            ),
            _tableCell(widget.loan.purpose, width: 150),
          ],
        ),
      ),
    );
  }

  Widget _tableCell(String text, {double? width, bool bold = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? CupertinoColors.label,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
    );
  }
}
import 'package:flutter/cupertino.dart';

import '../../models/app_models.dart';
import '../widgets/app_section_card.dart';

class SavingsPanel extends StatelessWidget {
  const SavingsPanel({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.selectedTransactionType,
    required this.amountController,
    required this.referenceController,
    required this.remarksController,
    required this.currentBalance,
    required this.history,
    required this.onSelectMember,
    required this.onSelectTransactionType,
    required this.onSubmit,
    required this.formatMoney,
    required this.formatDate,
  });

  final List<MemberRecord> members;
  final int? selectedMemberId;
  final String selectedTransactionType;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final TextEditingController remarksController;
  final double currentBalance;
  final List<SavingsTransactionRecord> history;
  final ValueChanged<int?> onSelectMember;
  final ValueChanged<String?> onSelectTransactionType;
  final VoidCallback onSubmit;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;

  Future<void> _pickMember(BuildContext context) async {
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
                          onSelectMember(member.memberId);
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
                              if (member.memberId == selectedMemberId)
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

  Future<void> _pickType(BuildContext context) async {
    final List<String> types = <String>['DEPOSIT', 'WITHDRAWAL'];
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Transaction Type',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                ...types.map((String type) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSelectTransactionType(type);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: CupertinoColors.separator),
                        ),
                      ),
                      child: Text(
                        type[0].toUpperCase() + type.substring(1).toLowerCase(),
                        style: const TextStyle(color: CupertinoColors.label),
                      ),
                    ),
                  );
                }),
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

  @override
  Widget build(BuildContext context) {
    final String selectedMemberName = selectedMemberId == null
        ? 'None'
        : (members
                .where((MemberRecord m) => m.memberId == selectedMemberId)
                .firstOrNull
                ?.fullName ??
            'Unknown');

    final Widget transactionForm = AppSectionCard(
      title: 'New Transaction',
      icon: CupertinoIcons.add_circled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _selectorTile(
            'Member',
            selectedMemberName,
            () => _pickMember(context),
          ),
          const SizedBox(height: 16),
          _selectorTile(
            'Type',
            selectedTransactionType[0].toUpperCase() +
                selectedTransactionType.substring(1).toLowerCase(),
            () => _pickType(context),
          ),
          const SizedBox(height: 16),
          _field(
            'AMOUNT',
            amountController,
            'Enter amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          _field('REFERENCE NO.', referenceController, 'Enter reference number'),
          const SizedBox(height: 16),
          _field('REMARKS', remarksController, 'Enter remarks'),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.topLeft,
            child: CupertinoButton.filled(
              onPressed: onSubmit,
              child: const Text('Post Transaction'),
            ),
          ),
        ],
      ),
    );

    final Widget ledgerCard = AppSectionCard(
      title: 'Savings Ledger',
      subtitle: selectedMemberId == null
          ? 'Select a member to view'
          : 'Member: $selectedMemberName',
      icon: CupertinoIcons.list_bullet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (selectedMemberId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGroupedBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'CURRENT BALANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.secondaryLabel,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(currentBalance),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No transactions found for this member.',
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              children: history
                  .map((SavingsTransactionRecord row) =>
                      _TransactionRow(row: row, formatDate: formatDate, formatMoney: formatMoney))
                  .toList(),
            ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useTwoColumns = constraints.maxWidth >= 1000;

          if (useTwoColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 2, child: transactionForm),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: ledgerCard),
              ],
            );
          }

          return Column(
            children: <Widget>[
              transactionForm,
              const SizedBox(height: 16),
              ledgerCard,
            ],
          );
        },
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.row,
    required this.formatDate,
    required this.formatMoney,
  });

  final SavingsTransactionRecord row;
  final String Function(DateTime) formatDate;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final bool isDeposit = row.transactionType.toUpperCase() == 'DEPOSIT';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isDeposit
                ? CupertinoIcons.arrow_down_circle_fill
                : CupertinoIcons.arrow_up_circle_fill,
            color: isDeposit
                ? CupertinoColors.activeGreen
                : CupertinoColors.systemRed,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${isDeposit ? "Deposit" : "Withdrawal"} - ${row.referenceNo.isEmpty ? "No Ref" : row.referenceNo}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDate(row.transactionDate)} • ${row.remarks.isEmpty ? "No remarks" : row.remarks}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isDeposit ? "+" : "-"}${formatMoney(row.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDeposit
                  ? CupertinoColors.activeGreen
                  : CupertinoColors.systemRed,
            ),
          ),
        ],
      ),
    );
  }
}

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
                    onSelectMember(member.memberId);
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

  Future<void> _pickType(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select Transaction Type'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onSelectTransactionType('DEPOSIT');
              },
              child: const Text('Deposit'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onSelectTransactionType('WITHDRAWAL');
              },
              child: const Text('Withdrawal'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

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

  @override
  Widget build(BuildContext context) {
    String selectedMemberLabel = 'Select member';
    for (final MemberRecord member in members) {
      if (member.memberId == selectedMemberId) {
        selectedMemberLabel = member.fullName;
        break;
      }
    }

    final Widget transactionCard = AppSectionCard(
      title: 'Post Savings Transaction',
      subtitle:
          'Withdrawals are validated on SQL side to prevent negative balances.',
      icon: CupertinoIcons.tray_arrow_down_fill,
      child: members.isEmpty
          ? const Text('Add a member first before posting transactions.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _selectorTile(
                  'Member',
                  selectedMemberLabel,
                  () => _pickMember(context),
                ),
                const SizedBox(height: 12),
                _selectorTile(
                  'Type',
                  selectedTransactionType,
                  () => _pickType(context),
                ),
                const SizedBox(height: 12),
                _field(
                  amountController,
                  'Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _field(referenceController, 'Reference No.'),
                const SizedBox(height: 12),
                _field(remarksController, 'Remarks'),
                const SizedBox(height: 12),
                Text(
                  'Current Balance: ${formatMoney(currentBalance)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
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
      title: 'Savings Ledger (Recent)',
      icon: CupertinoIcons.doc_text_search,
      child: history.isEmpty
          ? const Text('No transactions for selected member.')
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: history
                        .map((SavingsTransactionRecord row) =>
                            _LedgerSummaryCard(
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
                            _tableCell('Type', width: 100, header: true),
                            _tableCell('Amount', width: 110, header: true),
                            _tableCell('Reference', width: 140, header: true),
                            _tableCell('Remarks', width: 160, header: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...history.map((SavingsTransactionRecord row) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                CupertinoColors.secondarySystemGroupedBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: <Widget>[
                              _tableCell(
                                formatDate(row.transactionDate),
                                width: 100,
                              ),
                              _tableCell(row.transactionType, width: 100),
                              _tableCell(formatMoney(row.amount), width: 110),
                              _tableCell(
                                row.referenceNo.isEmpty
                                    ? '-'
                                    : row.referenceNo,
                                width: 140,
                              ),
                              _tableCell(
                                row.remarks.isEmpty ? '-' : row.remarks,
                                width: 160,
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
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useTwoColumns = constraints.maxWidth >= 900;

          if (useTwoColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 2, child: transactionCard),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: ledgerCard),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              transactionCard,
              const SizedBox(height: 10),
              Container(height: 1, color: CupertinoColors.separator),
              const SizedBox(height: 10),
              ledgerCard,
            ],
          );
        },
      ),
    );
  }
}

class _LedgerSummaryCard extends StatefulWidget {
  const _LedgerSummaryCard({
    required this.row,
    required this.formatMoney,
    required this.formatDate,
  });

  final SavingsTransactionRecord row;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;

  @override
  State<_LedgerSummaryCard> createState() => _LedgerSummaryCardState();
}

class _LedgerSummaryCardState extends State<_LedgerSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isDeposit = widget.row.transactionType.toUpperCase() == 'DEPOSIT';

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
                        widget.formatDate(widget.row.transactionDate),
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
                              color: isDeposit
                                  ? CupertinoColors.activeGreen.withValues(alpha: 0.1)
                                  : CupertinoColors.systemOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.row.transactionType,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDeposit ? CupertinoColors.activeGreen : CupertinoColors.systemOrange,
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
                              widget.formatMoney(widget.row.amount),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.label,
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
                  Text('Reference: ${widget.row.referenceNo.isEmpty ? '-' : widget.row.referenceNo}', style: const TextStyle(fontSize: 13, color: CupertinoColors.label)),
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



import 'package:flutter/cupertino.dart';

import '../../models/app_models.dart';
import '../widgets/app_section_card.dart';

class ReportsPanel extends StatelessWidget {
  const ReportsPanel({
    super.key,
    required this.reportYear,
    required this.reportMonth,
    required this.isGenerating,
    required this.summary,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onGenerate,
    required this.formatMoney,
  });

  final int reportYear;
  final int reportMonth;
  final bool isGenerating;
  final MonthlyFinancialSummary? summary;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<int?> onMonthChanged;
  final VoidCallback onGenerate;
  final String Function(double) formatMoney;

  Future<void> _pickYear(BuildContext context, List<int> years) async {
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 300,
            constraints: const BoxConstraints(maxHeight: 400),
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
                    'Select Year',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: years.length,
                    itemBuilder: (BuildContext context, int index) {
                      final int year = years[index];
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onYearChanged(year);
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
                            year.toString(),
                            style: const TextStyle(
                              color: CupertinoColors.label,
                            ),
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

  Future<void> _pickMonth(BuildContext context) async {
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 300,
            constraints: const BoxConstraints(maxHeight: 400),
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
                    'Select Month',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: 12,
                    itemBuilder: (BuildContext context, int index) {
                      final int month = index + 1;
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onMonthChanged(month);
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
                            month.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: CupertinoColors.label,
                            ),
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

  Widget _selectorTile(String label, String value, VoidCallback onTap) {
    return CupertinoButton(
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
                '$label: $value',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final List<int> years = List<int>.generate(11, (int i) => currentYear - 5 + i);

    final Widget controlsCard = AppSectionCard(
      title: 'Report Period',
      icon: CupertinoIcons.calendar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _selectorTile(
                  'Year',
                  reportYear.toString(),
                  () => _pickYear(context, years),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _selectorTile(
                  'Month',
                  reportMonth.toString().padLeft(2, '0'),
                  () => _pickMonth(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.topLeft,
            child: CupertinoButton.filled(
              onPressed: isGenerating ? null : onGenerate,
              child: isGenerating
                  ? const CupertinoActivityIndicator()
                  : const Text('Generate Monthly Report'),
            ),
          ),
        ],
      ),
    );

    final Widget resultCard = AppSectionCard(
      title: 'Financial Results',
      subtitle: 'Period: $reportYear-${reportMonth.toString().padLeft(2, '0')}',
      icon: CupertinoIcons.doc_plaintext,
      child: summary == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No report generated for this period.',
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: <Widget>[
                _reportRow('Deposits', formatMoney(summary!.deposits)),
                _reportRow('Withdrawals', formatMoney(summary!.withdrawals), isNegative: true),
                const Divider(),
                _reportRow('NET SAVINGS', formatMoney(summary!.netSavings), isBold: true),
                const SizedBox(height: 20),
                _reportRow('Loan Disbursements', formatMoney(summary!.loanDisbursements), isNegative: true),
                _reportRow('Loan Repayments', formatMoney(summary!.loanRepayments)),
                const Divider(),
                _reportRow('NET CASH FLOW', formatMoney(summary!.netCashFlow), isBold: true),
              ],
            ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              controlsCard,
              const SizedBox(height: 16),
              resultCard,
            ],
          );
        },
      ),
    );
  }

  Widget _reportRow(String label, String value,
      {bool isNegative = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isBold ? CupertinoColors.label : CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            isNegative ? '($value)' : value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isNegative ? CupertinoColors.systemRed : CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

class Divider extends StatelessWidget {
  const Divider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: CupertinoColors.separator,
    );
  }
}

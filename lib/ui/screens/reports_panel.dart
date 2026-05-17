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
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select Year'),
          actions: years
              .map((int year) {
                return CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onYearChanged(year);
                  },
                  child: Text(year.toString()),
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

  Future<void> _pickMonth(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select Month'),
          actions: List<Widget>.generate(12, (int index) {
            final int month = index + 1;
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onMonthChanged(month);
              },
              child: Text(month.toString().padLeft(2, '0')),
            );
          }),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final List<int> years = List<int>.generate(9, (int index) {
      return currentYear - 4 + index;
    });

    final Widget controlsCard = AppSectionCard(
      title: 'Monthly Financial Summary',
      subtitle:
          'Aggregated savings and loan movement from SQL reporting views.',
      icon: CupertinoIcons.chart_bar_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _selectorTile(
            'Year',
            reportYear.toString(),
            () => _pickYear(context, years),
          ),
          const SizedBox(height: 12),
          _selectorTile(
            'Month',
            reportMonth.toString().padLeft(2, '0'),
            () => _pickMonth(context),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.topLeft,
            child: CupertinoButton.filled(
              onPressed: isGenerating ? null : onGenerate,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (isGenerating) ...<Widget>[
                    const CupertinoActivityIndicator(),
                    const SizedBox(width: 8),
                  ],
                  const Text('Generate Summary'),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final Widget resultCard = AppSectionCard(
      title: 'Summary Result',
      icon: CupertinoIcons.doc_text_search,
      child: summary == null
          ? const Text('No summary data for selected period.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Period: ${summary!.year}-${summary!.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _metricRow('Deposits', formatMoney(summary!.deposits)),
                _metricRow('Withdrawals', formatMoney(summary!.withdrawals)),
                _metricRow('Net Savings', formatMoney(summary!.netSavings)),
                _metricRow(
                  'Loan Disbursements',
                  formatMoney(summary!.loanDisbursements),
                ),
                _metricRow(
                  'Loan Repayments',
                  formatMoney(summary!.loanRepayments),
                ),
                _metricRow('Net Cash Flow', formatMoney(summary!.netCashFlow)),
              ],
            ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useTwoColumns = constraints.maxWidth >= 800;

          if (useTwoColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 2, child: controlsCard),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: resultCard),
              ],
            );
          }

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
}

import 'package:flutter/cupertino.dart';

import '../../models/app_models.dart';
import '../widgets/app_section_card.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.dashboard,
    required this.formatMoney,
  });

  final DashboardMetrics dashboard;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final Widget summarySection = AppSectionCard(
      title: 'Performance Snapshot',
      subtitle: 'Current totals from member, savings, and loan data.',
      icon: CupertinoIcons.chart_bar_alt_fill,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          _SummaryCard(
            icon: CupertinoIcons.person_2,
            title: 'Active Members',
            value: dashboard.activeMembers.toString(),
          ),
          _SummaryCard(
            icon: CupertinoIcons.money_dollar_circle,
            title: 'Total Savings',
            value: formatMoney(dashboard.totalSavings),
          ),
          _SummaryCard(
            icon: CupertinoIcons.doc_text,
            title: 'Active Loans',
            value: dashboard.activeLoans.toString(),
          ),
          _SummaryCard(
            icon: CupertinoIcons.creditcard,
            title: 'Loan Outstanding',
            value: formatMoney(dashboard.totalLoanOutstanding),
          ),
        ],
      ),
    );

    const Widget processSection = AppSectionCard(
      title: 'Digital Process',
      subtitle:
          'Operational flow aligned to single-source SQL records and automated reporting.',
      icon: CupertinoIcons.rectangle_stack_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('1. Register each member once with a unique member number.'),
          SizedBox(height: 8),
          Text('2. Record all deposits and withdrawals in one ledger.'),
          SizedBox(height: 8),
          Text(
            '3. Approve loans with standardized principal and interest terms.',
          ),
          SizedBox(height: 8),
          Text('4. Post loan payments to keep balances and status current.'),
          SizedBox(height: 8),
          Text('5. Generate monthly summaries from SQL views.'),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useTwoColumns = constraints.maxWidth >= 900;

          if (useTwoColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: summarySection),
                const SizedBox(width: 16),
                const Expanded(flex: 2, child: processSection),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              summarySection,
              const SizedBox(height: 16),
              processSection,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: CupertinoPopupSurface(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: CupertinoColors.activeBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: CupertinoTheme.of(context).textTheme.textStyle
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.secondaryLabel,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navTitleTextStyle
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

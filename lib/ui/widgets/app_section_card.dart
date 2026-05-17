import 'package:flutter/cupertino.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 20,
                  color: CupertinoColors.secondaryLabel,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (subtitle != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Text(
              subtitle!,
              style: theme.textTheme.textStyle.copyWith(
                color: CupertinoColors.secondaryLabel,
                fontSize: 13,
              ),
            ),
          ),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:splitwise/models/expense_analysis_models.dart';

/// A reusable card component for analysis sections
class AnalysisCard extends StatelessWidget {
  final String title;
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final Widget? headerWidget; // Optional widget for top-right corner
  final Widget child;
  final BorderSide outlineBorderSide;
  final BorderRadius borderRadius;

  const AnalysisCard({
    super.key,
    required this.title,
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    this.headerWidget,
    required this.child,
    required this.outlineBorderSide,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
          borderRadius: borderRadius, side: outlineBorderSide),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withValues(alpha: 0.95)
            ],
          ),
        ),
        padding: const EdgeInsets.all(kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: iconColor.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Icon(iconData, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                ]),
                if (headerWidget != null) headerWidget!,
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

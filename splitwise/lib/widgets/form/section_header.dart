import 'package:flutter/material.dart';

/// A reusable header component for form sections with icon and title
class SectionHeader extends StatelessWidget {
  /// The title text to display
  final String title;

  /// The icon to display next to the title
  final IconData icon;

  /// Optional custom color for the icon
  final Color? iconColor;

  /// Optional custom background color for the icon container
  final Color? iconBackgroundColor;

  /// Optional widget to display on the right side of the header
  final Widget? trailing;

  /// Optional custom padding for the header
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final effectiveIconBgColor =
        iconBackgroundColor ?? effectiveIconColor.withValues(alpha: 0.1);

    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveIconBgColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveIconColor.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

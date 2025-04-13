import 'package:flutter/material.dart';
import 'package:splitwise/widgets/common/enhanced_button.dart';

class ActionBottomBar extends StatelessWidget {
  final String actionText;
  final VoidCallback? onAction;
  final bool isLoading;
  final Widget? topContent;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final ButtonStyle? buttonStyle;
  final TextStyle? buttonTextStyle;

  const ActionBottomBar({
    super.key,
    required this.actionText,
    required this.onAction,
    this.isLoading = false,
    this.topContent,
    this.padding,
    this.decoration,
    this.buttonStyle,
    this.buttonTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Default decoration if none provided
    final effectiveDecoration = decoration ??
        BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
        );

    // Default padding if none provided
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    return Container(
      padding: effectivePadding,
      decoration: effectiveDecoration,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (topContent != null) ...[
              topContent!,
              const SizedBox(height: 12),
            ],
            EnhancedButton(
              content: actionText,
              onPressed: onAction,
              isLoading: isLoading,
              style: buttonStyle,
              textStyle: buttonTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a bottom bar with amount display for expense screens
  factory ActionBottomBar.withAmount({
    Key? key,
    required String actionText,
    required VoidCallback? onAction,
    required double amount,
    required String currency,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
    BoxDecoration? decoration,
    ButtonStyle? buttonStyle,
    TextStyle? buttonTextStyle,
  }) {
    return ActionBottomBar(
      key: key,
      actionText: actionText,
      onAction: onAction,
      isLoading: isLoading,
      padding: padding,
      decoration: decoration,
      buttonStyle: buttonStyle,
      buttonTextStyle: buttonTextStyle,
      topContent: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Text(
                    currency,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    amount.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), alpha ?? a);
  }
}

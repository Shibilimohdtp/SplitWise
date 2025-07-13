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

    // Enhanced default decoration matching new design style
    final effectiveDecoration = decoration ??
        BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        );

    // Enhanced default padding
    final effectivePadding = padding ?? const EdgeInsets.all(16);

    return Container(
      decoration: effectiveDecoration,
      child: SafeArea(
        child: Padding(
          padding: effectivePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (topContent != null) ...[
                topContent!,
                const SizedBox(height: 16),
              ],
              _buildEnhancedButton(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedButton(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.03),
            colorScheme.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: EnhancedButton(
          content: actionText,
          onPressed: onAction,
          isLoading: isLoading,
          style: buttonStyle ??
              ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
          textStyle: buttonTextStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A reusable card component for form sections with consistent styling
class SectionCard extends StatelessWidget {
  /// The content to display inside the card
  final Widget child;

  /// Optional custom padding for the card content
  final EdgeInsetsGeometry? padding;

  /// Optional custom margin for the card
  final EdgeInsetsGeometry? margin;

  /// Optional custom border radius for the card
  final BorderRadius? borderRadius;

  /// Optional custom elevation for the card
  final double? elevation;

  /// Optional custom background color for the card
  final Color? backgroundColor;

  /// Optional custom border color for the card
  final Color? borderColor;

  /// Optional custom shadow color for the card
  final Color? shadowColor;

  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.backgroundColor,
    this.borderColor,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: elevation ?? 0,
      shadowColor: shadowColor ?? theme.shadowColor.withValues(alpha: 0.3),
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        side: BorderSide(
          color:
              borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor ?? theme.colorScheme.surface,
              (backgroundColor ?? theme.colorScheme.surface)
                  .withValues(alpha: 0.95),
            ],
          ),
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), alpha ?? a);
  }
}

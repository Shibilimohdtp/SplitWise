import 'package:flutter/material.dart';

/// A reusable loading indicator with optional text
class LoadingIndicator extends StatelessWidget {
  /// The size of the loading indicator
  final double size;

  /// The color of the loading indicator
  final Color? color;

  /// The stroke width of the loading indicator
  final double strokeWidth;

  /// Optional text to display below the loading indicator
  final String? text;

  /// Optional text style for the loading text
  final TextStyle? textStyle;

  /// Optional spacing between the indicator and text
  final double spacing;

  const LoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.0,
    this.text,
    this.textStyle,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    if (text == null) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          strokeWidth: strokeWidth,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            strokeWidth: strokeWidth,
          ),
        ),
        SizedBox(height: spacing),
        Text(
          text!,
          style: textStyle ??
              TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  /// Creates a loading indicator with text in a row layout
  static Widget row({
    Key? key,
    double size = 16.0,
    Color? color,
    double strokeWidth = 2.0,
    required String text,
    TextStyle? textStyle,
    double spacing = 8.0,
  }) {
    return _RowLoadingIndicator(
      key: key,
      size: size,
      color: color,
      strokeWidth: strokeWidth,
      text: text,
      textStyle: textStyle,
      spacing: spacing,
    );
  }
}

/// A loading indicator with text in a row layout
class _RowLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String text;
  final TextStyle? textStyle;
  final double spacing;

  const _RowLoadingIndicator({
    super.key,
    required this.size,
    this.color,
    required this.strokeWidth,
    required this.text,
    this.textStyle,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            strokeWidth: strokeWidth,
          ),
        ),
        SizedBox(width: spacing),
        Text(
          text,
          style: textStyle ??
              TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: effectiveColor,
              ),
        ),
      ],
    );
  }
}

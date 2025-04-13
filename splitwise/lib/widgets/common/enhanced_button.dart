import 'package:flutter/material.dart';

class EnhancedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final dynamic content;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final ButtonStyle? style;
  final TextStyle? textStyle;
  final Color? loadingIndicatorColor;
  final double loadingIndicatorSize;
  final String? loadingText;
  final Size? minimumSize;

  /// If [content] is a String, it will be displayed as text.
  /// If [content] is a Widget, it will be displayed directly.
  const EnhancedButton({
    super.key,
    required this.onPressed,
    required this.content,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.style,
    this.textStyle,
    this.loadingIndicatorColor,
    this.loadingIndicatorSize = 20.0,
    this.loadingText,
    this.minimumSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine effective colors
    final effectiveBackgroundColor = backgroundColor ?? colorScheme.primary;
    final effectiveForegroundColor = foregroundColor ?? colorScheme.onPrimary;

    // Create the button style
    final effectiveStyle = style ??
        FilledButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveForegroundColor,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: minimumSize ?? const Size(double.infinity, 48),
          disabledBackgroundColor:
              effectiveBackgroundColor.withValues(alpha: 0.5),
          disabledForegroundColor:
              effectiveForegroundColor.withValues(alpha: 0.7),
        );

    // Determine the effective text style
    final effectiveTextStyle = textStyle ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        );

    // Determine the effective loading indicator color
    final effectiveLoadingColor =
        loadingIndicatorColor ?? effectiveForegroundColor;

    return FilledButton(
      style: effectiveStyle,
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? _buildLoadingIndicator(effectiveLoadingColor)
          : _buildContent(effectiveTextStyle),
    );
  }

  /// Builds the content of the button based on the content type
  Widget _buildContent(TextStyle effectiveTextStyle) {
    if (content is String) {
      return Text(
        content as String,
        style: effectiveTextStyle,
      );
    } else if (content is Widget) {
      return content as Widget;
    } else {
      return const SizedBox.shrink();
    }
  }

  /// Builds the loading indicator with optional loading text
  Widget _buildLoadingIndicator(Color color) {
    if (loadingText != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: loadingIndicatorSize,
            height: loadingIndicatorSize,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            loadingText!,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: loadingIndicatorSize,
      height: loadingIndicatorSize,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 2,
      ),
    );
  }

  /// Creates a text button variant with the same API
  factory EnhancedButton.text({
    Key? key,
    required VoidCallback? onPressed,
    required dynamic content,
    bool isLoading = false,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    ButtonStyle? style,
    TextStyle? textStyle,
    Color? loadingIndicatorColor,
    double loadingIndicatorSize = 20.0,
    String? loadingText,
    Size? minimumSize,
  }) {
    return EnhancedButton(
      key: key,
      onPressed: onPressed,
      content: content,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      style: style ?? TextButton.styleFrom(),
      textStyle: textStyle,
      loadingIndicatorColor: loadingIndicatorColor,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingText: loadingText,
      minimumSize: minimumSize,
    );
  }

  /// Creates an outlined button variant with the same API
  factory EnhancedButton.outlined({
    Key? key,
    required VoidCallback? onPressed,
    required dynamic content,
    bool isLoading = false,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    ButtonStyle? style,
    TextStyle? textStyle,
    Color? loadingIndicatorColor,
    double loadingIndicatorSize = 20.0,
    String? loadingText,
    Size? minimumSize,
  }) {
    return EnhancedButton(
      key: key,
      onPressed: onPressed,
      content: content,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      style: style ?? OutlinedButton.styleFrom(),
      textStyle: textStyle,
      loadingIndicatorColor: loadingIndicatorColor,
      loadingIndicatorSize: loadingIndicatorSize,
      loadingText: loadingText,
      minimumSize: minimumSize,
    );
  }
}

extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), alpha ?? a);
  }
}

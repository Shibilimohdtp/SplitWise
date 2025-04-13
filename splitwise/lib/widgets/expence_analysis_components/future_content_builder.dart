import 'package:flutter/material.dart';
import 'package:splitwise/features/expense_tracking/models/expense_analysis_models.dart';

/// A generic FutureBuilder wrapper with loading, error, and empty state handling
class FutureContentBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final String loadingMessage;
  final String errorMessage;
  final String? errorDetails;
  final IconData? emptyDataIcon;
  final String? emptyDataMessage;
  final String? emptyDataDescription;
  final bool showLoadingIndicator;
  final Color? loadingIndicatorColor;

  const FutureContentBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingMessage = 'Loading...',
    this.errorMessage = 'Error loading data',
    this.errorDetails,
    this.emptyDataIcon,
    this.emptyDataMessage,
    this.emptyDataDescription,
    this.showLoadingIndicator = true,
    this.loadingIndicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return showLoadingIndicator
              ? _buildLoadingIndicator(context,
                  loadingIndicatorColor ?? colorScheme.primary, loadingMessage)
              : const SizedBox.shrink(); // Optionally hide indicator
        } else if (snapshot.hasError) {
          // Log error for debugging: print('FutureBuilder Error: ${snapshot.error}');
          return _buildErrorWidget(
              context, errorMessage, snapshot.error.toString());
        } else if (!snapshot.hasData ||
            (snapshot.data is Map && (snapshot.data as Map).isEmpty) ||
            (snapshot.data is List && (snapshot.data as List).isEmpty)) {
          // Handle empty map/list cases specifically if needed
          return emptyDataIcon != null && emptyDataMessage != null
              ? _buildEmptyDataWidget(context, colorScheme.primary,
                  emptyDataIcon!, emptyDataMessage!, emptyDataDescription ?? '')
              : Center(
                  child: Text(emptyDataMessage ?? 'No data available.',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant)));
        } else {
          return builder(context, snapshot.data as T);
        }
      },
    );
  }

  Widget _buildLoadingIndicator(
      BuildContext context, Color color, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 2.5)),
          const SizedBox(height: 16),
          Text(message,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(
      BuildContext context, String message, String details) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 32),
            const SizedBox(height: 12),
            Text(message,
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(details,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDataWidget(BuildContext context, Color color, IconData icon,
      String message, String description) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(kPadding),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

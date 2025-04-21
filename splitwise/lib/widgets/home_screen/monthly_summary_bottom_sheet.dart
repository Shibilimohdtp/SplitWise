import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/settings_service.dart';

/// Custom painter for the monthly trend chart with modern styling
class MonthlyTrendChartPainter extends CustomPainter {
  final List<double> monthlyData;
  final List<String> months;
  final double maxValue;
  final String currencySymbol;
  final Color barColor;
  final Color textColor;
  final Color gridColor;

  MonthlyTrendChartPainter({
    required this.monthlyData,
    required this.months,
    required this.maxValue,
    required this.currencySymbol,
    required this.barColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barWidth = size.width / 8; // Slightly narrower bars
    final double spacing =
        (size.width - (barWidth * 3)) / 4; // Space between bars
    final double maxHeight = size.height * 0.75; // Slightly taller bars
    final double bottomPadding =
        size.height * 0.18; // Space for labels at bottom

    // Paint for the bars with gradient
    final barPaint = Paint()..style = ui.PaintingStyle.fill;

    // Paint for the grid lines - more subtle
    final gridPaint = Paint()
      ..color = gridColor
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.8; // Thinner lines

    // Draw horizontal grid lines - fewer lines for cleaner look
    const int gridLines = 3;
    for (int i = 0; i <= gridLines; i++) {
      final double y =
          size.height - bottomPadding - (i * (maxHeight / gridLines));

      // Draw dashed grid lines for a more modern look
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      double startX = 0;

      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          gridPaint,
        );
        startX += dashWidth + dashSpace;
      }

      // Draw grid line labels (amounts) - more subtle
      if (maxValue > 0) {
        final double amount = (maxValue / gridLines) * i;
        final textSpan = TextSpan(
          text: '$currencySymbol${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(0, y - textPainter.height - 2), // Better positioning
        );
      }
    }

    // Draw bars and month labels
    for (int i = 0; i < monthlyData.length; i++) {
      final double value = monthlyData[i].abs();
      final double normalizedHeight =
          maxValue > 0 ? (value / maxValue) * maxHeight : 0;

      // Calculate bar position
      final double left = spacing + (i * (barWidth + spacing));
      final double top = size.height - bottomPadding - normalizedHeight;
      final double right = left + barWidth;
      final double bottom = size.height - bottomPadding;

      // Create gradient for bar
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          barColor,
          barColor.withValues(alpha: 0.7),
        ],
      );

      // Draw bar with gradient and shadow
      final rect = Rect.fromLTRB(left, top, right, bottom);
      final rrect = RRect.fromRectAndRadius(
          rect, const Radius.circular(8)); // More rounded corners

      // Add subtle shadow
      canvas.drawRRect(
        rrect.shift(const Offset(0, 2)),
        Paint()..color = barColor.withValues(alpha: 0.1),
      );

      // Draw the bar with gradient
      barPaint.shader = gradient.createShader(rect);
      canvas.drawRRect(rrect, barPaint);

      // Draw month label - cleaner typography
      final textSpan = TextSpan(
        text: months[i],
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500, // Slightly less bold
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (barWidth / 2) - (textPainter.width / 2),
            bottom + 10), // Better spacing
      );

      // Draw value on top of bar - cleaner look
      if (normalizedHeight > 0) {
        final valueSpan = TextSpan(
          text: '$currencySymbol${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        );
        final valuePainter = TextPainter(
          text: valueSpan,
          textDirection: ui.TextDirection.ltr,
        );
        valuePainter.layout();
        valuePainter.paint(
          canvas,
          Offset(left + (barWidth / 2) - (valuePainter.width / 2),
              top - valuePainter.height - 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// A widget that displays a monthly summary bottom sheet
class MonthlySummaryBottomSheet {
  /// Shows the monthly summary bottom sheet
  static Future<void> show(BuildContext context,
      Map<String, dynamic> summaryData, String userId) async {
    // Extract data from the summary
    final thisMonthTotal = summaryData['thisMonthTotal'] as double;
    final lastMonthTotal = summaryData['lastMonthTotal'] as double;
    final twoMonthsAgoTotal = summaryData['twoMonthsAgoTotal'] as double;
    final monthlyChangePercent = summaryData['monthlyChangePercent'] as double;

    // First, fetch the top categories
    final topCategories = await _fetchTopCategories(userId);

    // Check if the context is still valid
    if (!context.mounted) return;

    // Get all theme data
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    final currencySymbol = settingsService.currency;

    // Determine if the change is positive or negative
    final isPositiveChange = monthlyChangePercent >= 0;
    final changeColor =
        isPositiveChange ? colorScheme.tertiary : colorScheme.error;

    // Show the bottom sheet with enhanced design
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      elevation: 8, // Add elevation for depth
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)), // More rounded corners
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                  20, 12, 20, 20), // Increased padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced drag handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  // Enhanced title with better spacing
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons
                                .insights_rounded, // Rounded icon for modern look
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Monthly Expense Analysis',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: 0.1, // Improved typography
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Main content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Monthly trend section with enhanced styling
                        _buildSectionHeader(context, 'Monthly Trend'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.shadow.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color:
                                  colorScheme.outline.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Monthly trend chart
                              SizedBox(
                                height: 180,
                                child: _buildMonthlyTrendChart(
                                  context,
                                  [
                                    twoMonthsAgoTotal,
                                    lastMonthTotal,
                                    thisMonthTotal,
                                  ],
                                  currencySymbol,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Enhanced month-to-month comparison
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: changeColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: changeColor.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Month-to-month change:',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: changeColor.withValues(
                                                alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isPositiveChange
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            size: 14,
                                            color: changeColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${isPositiveChange ? '+' : ''}${monthlyChangePercent.toStringAsFixed(1)}%',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: changeColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Top categories section
                        _buildSectionHeader(context, 'Top Expense Categories'),
                        const SizedBox(height: 12),
                        if (topCategories.isEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.05),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.category_outlined,
                                    size: 32,
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No category data available',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start adding expenses to see your spending patterns',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topCategories.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final category = topCategories[index];
                              final categoryName = category['name'] as String;
                              final categoryAmount =
                                  category['amount'] as double;
                              final categoryPercentage =
                                  category['percentage'] as double;

                              // Determine icon based on category
                              IconData categoryIcon;
                              switch (categoryName.toLowerCase()) {
                                case 'food':
                                case 'groceries':
                                case 'dining':
                                case 'restaurant':
                                  categoryIcon = Icons.restaurant_outlined;
                                  break;
                                case 'transportation':
                                case 'travel':
                                  categoryIcon = Icons.directions_car_outlined;
                                  break;
                                case 'entertainment':
                                case 'movie':
                                  categoryIcon = Icons.movie_outlined;
                                  break;
                                case 'shopping':
                                  categoryIcon = Icons.shopping_bag_outlined;
                                  break;
                                case 'utilities':
                                case 'bills':
                                  categoryIcon = Icons.receipt_outlined;
                                  break;
                                case 'settlement':
                                  categoryIcon =
                                      Icons.account_balance_wallet_outlined;
                                  break;
                                default:
                                  categoryIcon = Icons.category_outlined;
                              }

                              // Enhanced category item with modern styling
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 4),
                                child: Row(
                                  children: [
                                    // Enhanced category icon with gradient
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primary
                                                .withValues(alpha: 0.15),
                                            colorScheme.primary
                                                .withValues(alpha: 0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.shadow
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        categoryIcon,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Category details with improved typography
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            categoryName,
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Enhanced progress bar
                                          Stack(
                                            children: [
                                              // Background with rounded corners
                                              Container(
                                                height: 6,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: colorScheme.outline
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                              // Foreground with gradient
                                              FractionallySizedBox(
                                                widthFactor:
                                                    categoryPercentage / 100,
                                                child: Container(
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        colorScheme.primary,
                                                        colorScheme.primary
                                                            .withValues(
                                                                alpha: 0.8),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Amount and percentage with improved styling
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$currencySymbol${categoryAmount.abs().toStringAsFixed(2)}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${categoryPercentage.toStringAsFixed(1)}%',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 24),
                        // Summary section with enhanced styling
                        _buildSectionHeader(context, 'Summary'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.shadow.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color:
                                  colorScheme.outline.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow(
                                context,
                                'Total Expenses This Month:',
                                '$currencySymbol${thisMonthTotal.abs().toStringAsFixed(2)}',
                                Icons.account_balance_wallet_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                context,
                                'Average Daily Expense:',
                                '$currencySymbol${(thisMonthTotal.abs() / 30).toStringAsFixed(2)}',
                                Icons.calendar_today_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                context,
                                'Month-to-Month Change:',
                                '${isPositiveChange ? '+' : ''}${monthlyChangePercent.toStringAsFixed(1)}%',
                                isPositiveChange
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                valueColor: changeColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Helper method to build modern section headers
  static Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Modern section title with better typography
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 12),
          // Gradient divider for visual interest
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.5),
                    colorScheme.outline.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build modern summary rows
  static Widget _buildSummaryRow(
      BuildContext context, String label, String value, IconData icon,
      {Color? valueColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label with enhanced icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Value with enhanced styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (valueColor ?? colorScheme.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build monthly trend chart
  static Widget _buildMonthlyTrendChart(
      BuildContext context, List<double> monthlyData, String currencySymbol) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get month names for the last 3 months
    final now = DateTime.now();
    final monthFormat = DateFormat('MMM');
    final months = [
      monthFormat.format(DateTime(now.year, now.month - 2)),
      monthFormat.format(DateTime(now.year, now.month - 1)),
      monthFormat.format(now),
    ];

    // Find the maximum value for scaling
    final maxValue = monthlyData
        .reduce((max, value) => value.abs() > max.abs() ? value.abs() : max);

    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: MonthlyTrendChartPainter(
        monthlyData: monthlyData,
        months: months,
        maxValue: maxValue,
        currencySymbol: currencySymbol,
        barColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        gridColor: colorScheme.outline.withValues(alpha: 0.2),
      ),
    );
  }

  /// Helper method to fetch top expense categories
  static Future<List<Map<String, dynamic>>> _fetchTopCategories(
      String userId) async {
    try {
      // Get all groups the user is a member of
      final userGroups = await FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: userId)
          .get();

      // Get current month start date
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);

      // Map to store category totals
      final Map<String, double> categoryTotals = {};
      double totalExpenses = 0;

      // For each group, get expenses for this month
      for (var groupDoc in userGroups.docs) {
        final groupId = groupDoc.id;

        final expenses = await FirebaseFirestore.instance
            .collection('expenses')
            .where('groupId', isEqualTo: groupId)
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonthStart))
            .orderBy('date', descending: true)
            .get();

        // Calculate category totals
        for (var doc in expenses.docs) {
          final expense = Expense.fromFirestore(doc);

          // Skip settlement expenses for category analysis
          if (expense.category.toLowerCase() == 'settlement') continue;

          // Calculate user's share in this expense
          double userShare = 0;
          if (expense.payerId == userId) {
            // User paid, so it's the amount minus their own share
            userShare = expense.splitDetails[userId] ?? 0;
          } else {
            // User didn't pay, so it's what they owe
            userShare = expense.splitDetails[userId] ?? 0;
          }

          // Add to category total
          categoryTotals[expense.category] =
              (categoryTotals[expense.category] ?? 0) + userShare;
          totalExpenses += userShare;
        }
      }

      // Convert to list and sort by amount
      final List<Map<String, dynamic>> topCategories =
          categoryTotals.entries.map((entry) {
        return {
          'name': entry.key,
          'amount': entry.value,
          'percentage':
              totalExpenses > 0 ? (entry.value / totalExpenses) * 100 : 0,
        };
      }).toList();

      // Sort by amount (descending)
      topCategories.sort(
          (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

      // Return top 5 categories
      return topCategories.take(5).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching top categories: $e');
      }
      return [];
    }
  }
}

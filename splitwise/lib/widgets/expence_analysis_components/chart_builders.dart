import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/widgets/expence_analysis_components/user_avatar.dart';
import 'package:splitwise/utils/currency_utils.dart';

/// Modern chart builders following Material Design 3 principles
class ChartBuilders {
  // Enhanced color palette for better accessibility and visual hierarchy
  static const List<Color> _modernColors = [
    Color(0xFF6750A4), // Primary Purple
    Color(0xFF00695C), // Teal
    Color(0xFFD84315), // Deep Orange
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF2E7D32), // Green
    Color(0xFFC62828), // Red
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFF9800), // Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];

  /// Builds a modern line chart with enhanced animations and accessibility
  static LineChartData buildModernLineChart({
    required Map<String, double> data,
    required double maxY,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String currency,
    bool showGrid = true,
    bool animate = true,
  }) {
    final currencySymbol = getCurrencySymbol(currency);

    return LineChartData(
      // Enhanced grid with subtle design
      gridData: FlGridData(
        show: showGrid,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 5 : 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colorScheme.outline.withValues(alpha: 0.06),
          strokeWidth: 1,
          dashArray: [3, 6],
        ),
      ),

      // Modern title styling with better spacing
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: maxY > 0 ? maxY / 5 : 1,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  _formatCurrency(value, currencySymbol),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final months = data.keys.toList();
              final index = value.toInt();
              if (index >= 0 && index < months.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _formatMonth(months[index]),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),

      // Enhanced touch interactions
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchSpotThreshold: 25,
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 12,
          tooltipPadding: const EdgeInsets.all(12),
          tooltipMargin: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final month = data.keys.elementAt(spot.spotIndex);
              final amount = spot.y;
              return LineTooltipItem(
                '$currencySymbol${amount.toStringAsFixed(2)}',
                textTheme.titleSmall?.copyWith(
                      color: colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ) ??
                    const TextStyle(),
                children: [
                  TextSpan(
                    text: '\n${_formatMonth(month)}',
                    style: textTheme.bodySmall?.copyWith(
                      color:
                          colorScheme.onInverseSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),

      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: data.isNotEmpty ? data.length.toDouble() - 1 : 0,
      minY: 0,
      maxY: maxY * 1.15, // Optimized padding

      // Enhanced line styling
      lineBarsData: [
        LineChartBarData(
          spots: data.entries
              .map((e) => FlSpot(
                    data.keys.toList().indexOf(e.key).toDouble(),
                    e.value,
                  ))
              .toList(),
          isCurved: true,
          curveSmoothness: 0.35,
          color: colorScheme.primary,
          barWidth: 3.5,
          isStrokeCapRound: true,
          preventCurveOverShooting: true,

          // Modern dot styling
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 5,
              color: colorScheme.primary,
              strokeWidth: 2.5,
              strokeColor: colorScheme.surface,
            ),
          ),

          // Enhanced gradient
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.15),
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.primary.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a modern pie chart with enhanced animations and interactions
  static Widget buildPieChart({
    required Map<String, double> balances,
    required double totalExpenses,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String currency,
    required UserService userService,
    double size = 200,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        int touchedIndex = -1;

        return SizedBox(
          height: size,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: size * 0.25,
              startDegreeOffset: -90,

              // Enhanced touch interactions
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),

              sections: _buildPieChartSections(
                balances,
                totalExpenses,
                colorScheme,
                textTheme,
                touchedIndex,
                userService,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds modern pie chart sections with enhanced styling
  static List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> balances,
    double totalExpenses,
    ColorScheme colorScheme,
    TextTheme textTheme,
    int touchedIndex,
    UserService userService,
  ) {
    return List.generate(balances.length, (index) {
      final entry = balances.entries.elementAt(index);
      final isTouched = index == touchedIndex;
      final percentage = (entry.value.abs() / totalExpenses) * 100;
      final color = _getModernColor(index);

      return PieChartSectionData(
        color: color,
        value: entry.value.abs(),
        title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: isTouched ? 85 : 75,
        titleStyle: textTheme.labelMedium?.copyWith(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        titlePositionPercentageOffset: 0.6,

        // Enhanced badge positioning
        badgeWidget: percentage >= 12
            ? _buildModernBadge(entry.key, color, userService)
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    });
  }

  /// Builds a modern badge widget for pie chart sections
  static Widget _buildModernBadge(
    String userId,
    Color color,
    UserService userService,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: userService.getUserNameAndImage(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: const SizedBox.shrink(),
          );
        }

        final userName = snapshot.data!['name'] ?? '?';
        final profileImageUrl = snapshot.data!['profileImageUrl'];

        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: UserAvatar(
            userName: userName,
            profileImageUrl: profileImageUrl,
            radius: 10,
            backgroundColor: color.withValues(alpha: 0.1),
            foregroundColor: color,
          ),
        );
      },
    );
  }

  /// Builds a modern legend with enhanced styling and layout
  static Widget buildModernLegend({
    required Map<String, double> balances,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String currency,
    required UserService userService,
    bool isCompact = false,
  }) {
    final currencySymbol = getCurrencySymbol(currency);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Expense Distribution',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLegendItems(
            balances,
            colorScheme,
            textTheme,
            currencySymbol,
            userService,
            isCompact,
          ),
        ],
      ),
    );
  }

  /// Builds legend items with modern styling
  static Widget _buildLegendItems(
    Map<String, double> balances,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String currencySymbol,
    UserService userService,
    bool isCompact,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(balances.length, (index) {
        final entry = balances.entries.elementAt(index);
        final color = _getModernColor(index);

        return FutureBuilder<String>(
          future: userService.isUser(entry.key).then((isUser) =>
              isUser ? userService.getUserName(entry.key) : entry.key),
          builder: (context, nameSnapshot) {
            if (!nameSnapshot.hasData) {
              return _buildLegendItemSkeleton(color);
            }

            return _buildLegendItem(
              nameSnapshot.data!,
              entry.value,
              color,
              colorScheme,
              textTheme,
              currencySymbol,
              isCompact,
            );
          },
        );
      }),
    );
  }

  /// Builds individual legend item
  static Widget _buildLegendItem(
    String name,
    double value,
    Color color,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String currencySymbol,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($currencySymbol${value.abs().toStringAsFixed(2)})',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds skeleton for loading legend items
  static Widget _buildLegendItemSkeleton(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  static Color _getModernColor(int index) {
    return _modernColors[index % _modernColors.length];
  }

  static String _formatCurrency(double value, String symbol) {
    if (value >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${value.toInt()}';
  }

  static String _formatMonth(String month) {
    return month.length >= 3 ? month.substring(0, 3) : month;
  }
}

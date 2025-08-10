import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
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

    if (data.isEmpty) return LineChartData();

    final entries = data.entries.toList();
    final spots = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value.value;
      return FlSpot(index.toDouble(), value);
    }).toList();

    return LineChartData(
      // Enhanced grid with subtle design and better intervals
      gridData: FlGridData(
        show: showGrid,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 4 : 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colorScheme.outline.withValues(alpha: 0.1),
          strokeWidth: 1,
          dashArray: [8, 4],
        ),
      ),

      // Enhanced titles with smart formatting
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: maxY > 0 ? maxY / 4 : 1,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _formatCurrencyCompact(value, currencySymbol),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= entries.length) {
                return const SizedBox.shrink();
              }

              final key = entries[index].key;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  key,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      // Enhanced border styling
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          left: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),

      minX: 0,
      maxX: (entries.length - 1).toDouble(),
      minY: 0,
      maxY: maxY * 1.2,

      // Enhanced line styling with gradients and shadows
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.8),
              colorScheme.primary,
              colorScheme.tertiary.withValues(alpha: 0.9),
            ],
          ),

          // Enhanced dot styling
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: colorScheme.surface,
                strokeWidth: 3,
                strokeColor: colorScheme.primary,
              );
            },
          ),

          // Enhanced gradient fill with multiple stops
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withValues(alpha: 0.15),
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.primary.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),

          // Add shadow effect
          shadow: Shadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ),
      ],

      // Enhanced touch interactions with tooltips and haptic feedback
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => colorScheme.inverseSurface,
          tooltipRoundedRadius: 12,
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          tooltipMargin: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index >= 0 && index < entries.length) {
                final entry = entries[index];
                return LineTooltipItem(
                  '${entry.key}\n$currencySymbol${entry.value.toStringAsFixed(2)}',
                  TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          // Add haptic feedback on touch (requires import 'package:flutter/services.dart')
          if (event is FlTapUpEvent) {
            HapticFeedback.lightImpact();
          }
        },
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: colorScheme.primary.withValues(alpha: 0.8),
                strokeWidth: 2,
                dashArray: [4, 4],
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: colorScheme.primary,
                    strokeWidth: 3,
                    strokeColor: colorScheme.surface,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
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

  /// Formats currency values compactly (e.g., 2.5k, 1.2M)
  static String _formatCurrencyCompact(double value, String currencySymbol) {
    if (value == 0) return '0';

    if (value >= 1000000) {
      return '$currencySymbol${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '$currencySymbol${(value / 1000).toStringAsFixed(0)}k';
    } else {
      return '$currencySymbol${value.toStringAsFixed(0)}';
    }
  }

  // Helper methods
  static Color _getModernColor(int index) {
    return _modernColors[index % _modernColors.length];
  }
}

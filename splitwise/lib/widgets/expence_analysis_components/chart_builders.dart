import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:splitwise/features/expense_tracking/models/expense_analysis_models.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/widgets/expence_analysis_components/user_avatar.dart';

/// Utility class for building charts for expense analysis
class ChartBuilders {
  /// Builds a line chart for monthly expenses
  static LineChartData buildLineChartData(Map<String, double> data, double maxY,
      ColorScheme colorScheme, TextTheme textTheme, String currencySymbol) {
    final lineTouchData = LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchSpotThreshold: 20,
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final month = data.keys.elementAt(spot.spotIndex);
            final amount = spot.y;
            return LineTooltipItem(
              '$currencySymbol${amount.toStringAsFixed(2)}\n',
              TextStyle(
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              children: [
                TextSpan(
                    text: month,
                    style:
                        TextStyle(color: colorScheme.onSecondary, fontSize: 12))
              ],
            );
          }).toList();
        },
      ),
    );

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 4 : 1,
        getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
            dashArray: [5, 5]),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: maxY > 0 ? maxY / 4 : 1,
          getTitlesWidget: (value, meta) => value == 0
              ? const Text('')
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('$currencySymbol${value.toInt()}',
                      style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500)),
                ),
        )),
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
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(months[index].substring(0, 3),
                      style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500)));
            }
            return const Text('');
          },
        )),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: data.isNotEmpty ? data.length.toDouble() - 1 : 0,
      minY: 0,
      maxY: maxY * 1.2, // Add padding to max Y
      lineTouchData: lineTouchData, // Apply touch data
      lineBarsData: [
        LineChartBarData(
          spots: data.entries
              .map((e) =>
                  FlSpot(data.keys.toList().indexOf(e.key).toDouble(), e.value))
              .toList(),
          isCurved: true,
          curveSmoothness: 0.3,
          color: colorScheme.secondary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                      radius: 4,
                      color: colorScheme.secondary,
                      strokeWidth: 2,
                      strokeColor: colorScheme.surface)),
          belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [
                colorScheme.secondary.withValues(alpha: 0.3),
                colorScheme.secondary.withValues(alpha: 0.0)
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        ),
      ],
    );
  }

  /// Builds a pie chart for expense distribution
  static PieChartData buildPieChartData(
      Map<String, double> balances,
      double totalExpenses,
      ColorScheme colorScheme,
      TextTheme textTheme,
      int touchedIndex) {
    return PieChartData(
      sectionsSpace: 4,
      centerSpaceRadius: 50,
      pieTouchData: PieTouchData(
        // Add touch interaction
        touchCallback: (FlTouchEvent event, pieTouchResponse) {
          // setState(() { // Requires making this stateful or managing state differently
          if (!event.isInterestedForInteractions ||
              pieTouchResponse == null ||
              pieTouchResponse.touchedSection == null) {
            // touchedIndex = -1;
            return;
          }
          // touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
          // });
        },
      ),
      sections: List.generate(balances.length, (index) {
        final entry = balances.entries.elementAt(index);
        final isTouched = index == touchedIndex;
        final double percentage = (entry.value.abs() / totalExpenses) * 100;
        final color = getDistributionColor(index);
        final radius = isTouched ? 100.0 : 90.0; // Increase radius on touch
        final titleStyle = TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

        return PieChartSectionData(
          color: color,
          value: entry.value.abs(),
          title: percentage >= 5
              ? '${percentage.toStringAsFixed(isTouched ? 1 : 0)}%'
              : '', // Show decimal on touch
          radius: radius,
          titleStyle: titleStyle,
          titlePositionPercentageOffset: 0.55,
          badgeWidget: buildPieChartBadge(entry.key, index, percentage >= 8,
              color), // Build badge conditionally
          badgePositionPercentageOffset: 0.8,
        );
      }),
    );
  }

  /// Builds a badge widget for pie chart sections
  static Widget buildPieChartBadge(
      String userId, int colorIndex, bool showBadge, Color color) {
    if (!showBadge) return const SizedBox.shrink(); // Don't build if not shown

    return FutureBuilder<Map<String, dynamic>>(
      future: UserService().getUserNameAndImage(userId),
      builder: (context, snapshot) {
        final userName = snapshot.data?['name'] ?? '?';
        final profileImageUrl = snapshot.data?['profileImageUrl'];
        if (userName.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1))
              ]),
          child: UserAvatar(
            userName: userName,
            profileImageUrl: profileImageUrl,
            radius: 8,
            backgroundColor: color.withValues(alpha: 0.2),
            foregroundColor: color.withValues(alpha: 0.9),
          ),
        );
      },
    );
  }

  /// Builds a legend for the pie chart
  static Widget buildPieChartLegend(
      Map<String, double> balances,
      ColorScheme colorScheme,
      TextTheme textTheme,
      String currencySymbol,
      UserService userService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Members',
            style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.tertiary,
                letterSpacing: 0.2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(balances.length, (index) {
            final entry = balances.entries.elementAt(index);
            final color = getDistributionColor(index);
            return FutureBuilder<String>(
              // Fetch name for legend item
              future: userService.getUserName(entry.key),
              builder: (context, nameSnapshot) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: color.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              boxShadow: [
                                BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1))
                              ])),
                      const SizedBox(width: 8),
                      Text(nameSnapshot.data ?? '...',
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      Text(
                          '($currencySymbol${entry.value.abs().toStringAsFixed(2)})',
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

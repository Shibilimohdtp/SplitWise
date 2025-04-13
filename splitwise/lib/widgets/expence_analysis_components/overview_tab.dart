import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/features/expense_tracking/models/expense_analysis_models.dart';
import 'package:splitwise/widgets/expence_analysis_components/analysis_card.dart';
import 'package:splitwise/widgets/common/animated_wrapper.dart';
import 'package:splitwise/widgets/expence_analysis_components/future_content_builder.dart';
import 'package:splitwise/widgets/expence_analysis_components/chart_builders.dart';

class OverviewTab extends StatelessWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;
  final UserService userService;
  final BorderSide outlineBorderSide;
  final BorderRadius cardBorderRadius;

  const OverviewTab({
    super.key,
    required this.group,
    required this.expenseService,
    required this.settingsService,
    required this.userService,
    required this.outlineBorderSide,
    required this.cardBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(kPadding),
      itemCount: 3, // Number of overview cards
      itemBuilder: (context, index) {
        return AnimatedWrapper.staggered(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: kPadding),
            child: _buildOverviewCard(index, context),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(int index, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    switch (index) {
      case 0:
        return _buildTotalExpensesCard(context, colorScheme, textTheme);
      case 1:
        return _buildMonthlyExpensesCard(context, colorScheme, textTheme);
      case 2:
        return _buildExpenseDistributionCard(context, colorScheme, textTheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTotalExpensesCard(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return AnalysisCard(
      title: 'Total Expenses',
      iconData: Icons.account_balance_wallet_outlined,
      iconColor: colorScheme.primary,
      iconBgColor: colorScheme.primary.withValues(alpha: 0.1),
      outlineBorderSide: outlineBorderSide,
      borderRadius: cardBorderRadius,
      child: FutureContentBuilder<double>(
        future: calculateTotalExpenses(expenseService, group.id),
        loadingMessage: 'Calculating total...',
        builder: (context, total) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: total),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: kPadding),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(settingsService.currency,
                        style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary)),
                    const SizedBox(width: 4),
                    Text(NumberFormat('#,##0.00').format(value),
                        style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMonthlyExpensesCard(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return AnalysisCard(
      title: 'Monthly Trend',
      iconData: Icons.insert_chart_outlined,
      iconColor: colorScheme.secondary,
      iconBgColor: colorScheme.secondary.withValues(alpha: 0.1),
      outlineBorderSide: outlineBorderSide,
      borderRadius: cardBorderRadius,
      headerWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Last 6 months',
            style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ),
      child: SizedBox(
        height: 200,
        child: FutureContentBuilder<Map<String, double>>(
          future: getMonthlyExpenses(expenseService, group.id),
          loadingMessage: 'Loading expense data...',
          emptyDataIcon: Icons.show_chart,
          emptyDataMessage: 'No expense data available',
          emptyDataDescription: 'Start adding expenses to see monthly trends',
          builder: (context, data) {
            final maxY = data.values.isEmpty
                ? 0.0
                : data.values.reduce((max, v) => max > v ? max : v);
            return LineChart(
              ChartBuilders.buildLineChartData(
                data,
                maxY,
                colorScheme,
                textTheme,
                settingsService.currency,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpenseDistributionCard(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return AnalysisCard(
      title: 'Expense Distribution',
      iconData: Icons.pie_chart_outline,
      iconColor: colorScheme.tertiary,
      iconBgColor: colorScheme.tertiary.withValues(alpha: 0.1),
      outlineBorderSide: outlineBorderSide,
      borderRadius: cardBorderRadius,
      headerWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('By Member',
            style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: FutureContentBuilder<Map<String, double>>(
              future: expenseService.calculateBalances(group.id),
              loadingMessage: 'Loading distribution data...',
              emptyDataIcon: Icons.pie_chart_outline,
              emptyDataMessage: 'No distribution data',
              emptyDataDescription: 'Add expenses to see member distribution',
              builder: (context, balances) {
                final totalExpenses = balances.values
                    .fold<double>(0, (sum, value) => sum + value.abs());
                if (totalExpenses == 0) {
                  return _buildEmptyDataWidget(
                    context,
                    colorScheme.tertiary,
                    Icons.pie_chart_outline,
                    'No expenses to display',
                    'All balances are currently settled',
                  );
                }
                return PieChart(
                  ChartBuilders.buildPieChartData(
                    balances,
                    totalExpenses,
                    colorScheme,
                    textTheme,
                    -1, // No touched index initially
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: kPadding),
          FutureContentBuilder<Map<String, double>>(
            future: expenseService.calculateBalances(group.id),
            loadingMessage: '', // No separate loading for legend needed
            showLoadingIndicator: false, // Hide indicator
            builder: (context, balances) {
              if (balances.isEmpty || balances.values.every((v) => v == 0)) {
                return const SizedBox.shrink();
              }
              return ChartBuilders.buildPieChartLegend(
                balances,
                colorScheme,
                textTheme,
                settingsService.currency,
                userService,
              );
            },
          ),
        ],
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

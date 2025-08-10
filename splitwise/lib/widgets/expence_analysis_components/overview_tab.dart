import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/models/expense_analysis_models.dart';
import 'package:splitwise/utils/currency_utils.dart';
import 'package:splitwise/widgets/common/animated_wrapper.dart';
import 'package:splitwise/widgets/expence_analysis_components/future_content_builder.dart';
import 'package:splitwise/widgets/expence_analysis_components/chart_builders.dart';

enum TimeRange {
  oneWeek(days: 7, label: '1W', fullLabel: '1 Week'),
  oneMonth(days: 30, label: '1M', fullLabel: '1 Month'),
  sixMonths(days: 180, label: '6M', fullLabel: '6 Months');

  const TimeRange({
    required this.days,
    required this.label,
    required this.fullLabel,
  });

  final int days;
  final String label;
  final String fullLabel;
}

class OverviewTab extends StatefulWidget {
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
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  TimeRange selectedTimeRange = TimeRange.sixMonths;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
        return _buildMonthlyExpensesCard(
          context,
          colorScheme,
          textTheme,
          expensesFuture: getExpensesForTimeRange(
            widget.expenseService,
            widget.group.id,
            selectedTimeRange,
          ),
          currency: widget.settingsService.currency,
        );
      case 2:
        return _buildExpenseDistributionCard(
          context,
          colorScheme,
          textTheme,
          balancesFuture:
              widget.expenseService.calculateBalances(widget.group.id),
          currency: widget.settingsService.currency,
          userService: widget.userService,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTotalExpensesCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final settingsService = Provider.of<SettingsService>(context);
    final currencySymbol = getCurrencySymbol(settingsService.currency);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            colorScheme,
            textTheme,
            icon: Icons.account_balance_wallet_rounded,
            title: 'Total Expenses',
            subtitle: 'Overall spending in the group',
            primaryColor: colorScheme.secondary,
            badgeText: 'Summary',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.secondary.withValues(alpha: 0.03),
                    colorScheme.secondary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FutureContentBuilder<double>(
                  future: calculateTotalExpenses(
                      widget.expenseService, widget.group.id),
                  loadingMessage: 'Calculating total...',
                  builder: (context, total) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: total),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total Spent',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  currencySymbol,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  NumberFormat('#,##0.00').format(value),
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.secondary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyExpensesCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required Future<Map<String, double>> expensesFuture,
    required String currency,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header with Time Range Selector
          _buildTrendHeaderWithSelector(
            context,
            colorScheme,
            textTheme,
          ),

          // Enhanced Content Container with increased height and better styling
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 280, // Increased height for better visibility
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.02),
                    colorScheme.primary.withValues(alpha: 0.06),
                    colorScheme.primary.withValues(alpha: 0.03),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FutureContentBuilder<Map<String, double>>(
                  future: expensesFuture,
                  loadingMessage: 'Analyzing spending patterns...',
                  emptyDataIcon: Icons.show_chart_rounded,
                  emptyDataMessage: 'No expense trends yet',
                  emptyDataDescription:
                      'Add expenses to track spending patterns',
                  builder: (context, data) {
                    if (data.isEmpty) {
                      return _buildEmptyStateWidget(
                        context,
                        colorScheme.primary,
                        Icons.trending_up_rounded,
                        'Start tracking expenses',
                        'Your spending trends will appear here',
                      );
                    }

                    final maxY = data.values.isEmpty
                        ? 0.0
                        : data.values.reduce((max, v) => max > v ? max : v);

                    return Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chart Header with Stats

                          // Main Chart Area
                          Expanded(
                            child: LineChart(
                              ChartBuilders.buildModernLineChart(
                                data: data,
                                maxY: maxY,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                                currency: currency,
                                showGrid: true,
                                animate: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Enhanced Insights Section
          _buildInsightsSection(
            context,
            colorScheme,
            textTheme,
            expensesFuture,
            currency,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendHeaderWithSelector(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.05),
            colorScheme.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Trends',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last ${selectedTimeRange.fullLabel.toLowerCase()}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Trending',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Time Range Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: TimeRange.values.map((timeRange) {
                final isSelected = selectedTimeRange == timeRange;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTimeRange = timeRange;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        timeRange.label,
                        textAlign: TextAlign.center,
                        style: textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseDistributionCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required Future<Map<String, double>> balancesFuture,
    required String currency,
    required dynamic userService,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          _buildHeader(
            context,
            colorScheme,
            textTheme,
            icon: Icons.donut_large_rounded,
            title: 'Expense Distribution',
            subtitle: 'By member',
            primaryColor: colorScheme.tertiary,
            badgeText: 'Analysis',
          ),

          // Enhanced Content Container
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.tertiary.withValues(alpha: 0.03),
                    colorScheme.tertiary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.tertiary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Pie Chart Section
                    FutureContentBuilder<Map<String, double>>(
                      future: balancesFuture,
                      loadingMessage: 'Calculating member contributions...',
                      emptyDataIcon: Icons.pie_chart_outline_rounded,
                      emptyDataMessage: 'No distribution data',
                      emptyDataDescription:
                          'Add expenses to see member breakdown',
                      builder: (context, balances) {
                        if (balances.isEmpty ||
                            balances.values.every((v) => v == 0)) {
                          return _buildEmptyStateWidget(
                            context,
                            colorScheme.tertiary,
                            Icons.donut_large_rounded,
                            'All settled up!',
                            'No outstanding balances between members',
                          );
                        }

                        final totalExpenses = balances.values
                            .fold<double>(0, (sum, value) => sum + value.abs());

                        return Container(
                          height: 240,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: ChartBuilders.buildPieChart(
                            balances: balances,
                            totalExpenses: totalExpenses,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            currency: currency,
                            userService: userService,
                            size: 200,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Legend Section
                    FutureContentBuilder<Map<String, double>>(
                      future: balancesFuture,
                      loadingMessage: '',
                      showLoadingIndicator: false,
                      builder: (context, balances) {
                        if (balances.isEmpty ||
                            balances.values.every((v) => v == 0)) {
                          return const SizedBox.shrink();
                        }

                        return ChartBuilders.buildModernLegend(
                          balances: balances,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          currency: currency,
                          userService: userService,
                          isCompact: false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Summary Section
          _buildSummarySection(
            context,
            colorScheme,
            textTheme,
            balancesFuture,
            currency,
          ),
        ],
      ),
    );
  }

  /// Builds modern header with enhanced styling
  static Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.05),
            primaryColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),

          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              badgeText,
              style: textTheme.labelSmall?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds empty state widget with modern styling
  static Widget _buildEmptyStateWidget(
    BuildContext context,
    Color primaryColor,
    IconData icon,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds insights section for monthly expenses
  static Widget _buildInsightsSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Future<Map<String, double>> expensesFuture,
    String currency,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: FutureBuilder<Map<String, double>>(
        future: expensesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final data = snapshot.data!;
          final values = data.values.toList();
          final avgExpense =
              values.fold<double>(0, (sum, val) => sum + val) / values.length;
          final trend =
              values.length > 1 ? values.last - values[values.length - 2] : 0;
          final trendIcon = trend > 0 ? Icons.trending_up : Icons.trending_down;
          final trendColor = trend > 0 ? Colors.red : Colors.green;

          return Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  context,
                  colorScheme,
                  textTheme,
                  'Average',
                  '${getCurrencySymbol(currency)}${avgExpense.toStringAsFixed(0)}',
                  Icons.analytics_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInsightItem(
                  context,
                  colorScheme,
                  textTheme,
                  'Trend',
                  '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(0)}',
                  trendIcon,
                  valueColor: trendColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds summary section for expense distribution
  static Widget _buildSummarySection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Future<Map<String, double>> balancesFuture,
    String currency,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: FutureBuilder<Map<String, double>>(
        future: balancesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final balances = snapshot.data!;
          final totalExpenses =
              balances.values.fold<double>(0, (sum, val) => sum + val.abs());
          final memberCount = balances.length;

          return Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  context,
                  colorScheme,
                  textTheme,
                  'Total',
                  '${getCurrencySymbol(currency)}${totalExpenses.toStringAsFixed(0)}',
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInsightItem(
                  context,
                  colorScheme,
                  textTheme,
                  'Members',
                  memberCount.toString(),
                  Icons.people_outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds individual insight item
  static Widget _buildInsightItem(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: textTheme.bodySmall?.copyWith(
                  color: valueColor ?? colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Helper function that you'll need to implement
Future<Map<String, double>> getExpensesForTimeRange(
  ExpenseService expenseService,
  String groupId,
  TimeRange timeRange,
) async {
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: timeRange.days));

  final expenses = await expenseService
      .getGroupExpenses(
        groupId,
        startDate: startDate,
        endDate: endDate,
      )
      .first;

  final Map<String, double> aggregatedExpenses = {};

  if (timeRange == TimeRange.oneWeek) {
    // For 1 week, show day names (Mon, Tue, Wed, etc.)
    for (int i = 6; i >= 0; i--) {
      final date = endDate.subtract(Duration(days: i));
      final dayKey = DateFormat('E').format(date); // Mon, Tue, Wed
      aggregatedExpenses[dayKey] = 0.0;
    }

    for (var expense in expenses) {
      final dayKey = DateFormat('E').format(expense.date);
      if (aggregatedExpenses.containsKey(dayKey)) {
        aggregatedExpenses[dayKey] =
            (aggregatedExpenses[dayKey] ?? 0) + expense.amount;
      }
    }
  } else if (timeRange == TimeRange.oneMonth) {
    // For 1 month, group by weeks (Week 1, Week 2, etc.) or show selective dates
    final weeklyData = <int, double>{};

    // Initialize 4 weeks
    for (int week = 1; week <= 4; week++) {
      weeklyData[week] = 0.0;
    }

    for (var expense in expenses) {
      final daysDiff = endDate.difference(expense.date).inDays;
      final weekNumber = (daysDiff / 7).floor() + 1;
      if (weekNumber >= 1 && weekNumber <= 4) {
        weeklyData[weekNumber] = (weeklyData[weekNumber] ?? 0) + expense.amount;
      }
    }

    // Convert to string keys
    weeklyData.forEach((week, amount) {
      aggregatedExpenses['Week $week'] = amount;
    });
  } else if (timeRange == TimeRange.sixMonths) {
    // For 6 months, use abbreviated month names (Jan, Feb, etc.)
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(endDate.year, endDate.month - i, 1);
      final monthKey = DateFormat('MMM').format(monthDate);
      aggregatedExpenses[monthKey] = 0.0;
    }

    for (var expense in expenses) {
      final monthKey = DateFormat('MMM').format(expense.date);
      if (aggregatedExpenses.containsKey(monthKey)) {
        aggregatedExpenses[monthKey] =
            (aggregatedExpenses[monthKey] ?? 0) + expense.amount;
      }
    }
  }

  return aggregatedExpenses;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// --- Constants ---
const double _kPadding = 16.0;
const double _kRadius = 16.0;
const Duration _kAnimDuration = Duration(milliseconds: 300);
const Duration _kCardAnimDuration = Duration(milliseconds: 400);

// --- Helper Classes ---
class Settlement {
  final String from;
  final String to;
  final double amount;

  Settlement({required this.from, required this.to, required this.amount});
}

// --- Main Widget ---
class ExpenseAnalysisScreen extends StatefulWidget {
  final Group group;
  const ExpenseAnalysisScreen({super.key, required this.group});

  @override
  ExpenseAnalysisScreenState createState() => ExpenseAnalysisScreenState();
}

class ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Cached Services ---
  late SettingsService _settingsService;
  late ExpenseService _expenseService;
  late UserService _userService;

  // --- Lifecycle ---
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Cache services in initState for easier access
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Common Styles
    final outlineColor = colorScheme.outline.withValues(alpha: 0.1);
    final outlineBorderSide = BorderSide(color: outlineColor, width: 1);
    final cardBorderRadius = BorderRadius.circular(_kRadius);
    final iconButtonStyle = IconButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        centerTitle: false,
        title: Text('Expense Analysis',
            style: textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
          style: iconButtonStyle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.info_outline,
                  size: 20, color: colorScheme.primary),
              onPressed: () => _showInfoDialog(context, colorScheme, textTheme),
              style: iconButtonStyle,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: _kPadding, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineColor),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 0, // Hidden by BoxDecoration indicator
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
              unselectedLabelStyle:
                  textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              splashBorderRadius: BorderRadius.circular(8),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Balances'),
                Tab(text: 'Settlements'),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: _kAnimDuration,
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildOverviewTab(
                colorScheme, textTheme, outlineBorderSide, cardBorderRadius),
            _buildBalancesTab(
                colorScheme, textTheme, outlineBorderSide, cardBorderRadius),
            _buildSettlementsTab(colorScheme, textTheme, outlineBorderSide),
          ],
        ),
      ),
    );
  }

  // --- Tab Builders ---

  Widget _buildOverviewTab(ColorScheme colorScheme, TextTheme textTheme,
      BorderSide outlineBorderSide, BorderRadius cardBorderRadius) {
    return ListView.builder(
      padding: const EdgeInsets.all(_kPadding),
      itemCount: 3, // Number of overview cards
      itemBuilder: (context, index) {
        return _AnimatedCardWrapper(
          // Extracted animation wrapper
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: _kPadding),
            child: _buildOverviewCard(index, colorScheme, textTheme,
                outlineBorderSide, cardBorderRadius),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(
      int index,
      ColorScheme colorScheme,
      TextTheme textTheme,
      BorderSide outlineBorderSide,
      BorderRadius cardBorderRadius) {
    switch (index) {
      case 0:
        return _buildTotalExpensesCard(
            colorScheme, textTheme, outlineBorderSide, cardBorderRadius);
      case 1:
        return _buildMonthlyExpensesCard(
            colorScheme, textTheme, outlineBorderSide, cardBorderRadius);
      case 2:
        return _buildExpenseDistributionCard(
            colorScheme, textTheme, outlineBorderSide, cardBorderRadius);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBalancesTab(ColorScheme colorScheme, TextTheme textTheme,
      BorderSide outlineBorderSide, BorderRadius cardBorderRadius) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: _kPadding, bottom: 12),
            child: Text('Member Balances',
                style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.2)),
          ),
          Expanded(
            child: _buildFutureContent<Map<String, double>>(
              // Use generic FutureBuilder helper
              future: _expenseService.calculateBalances(widget.group.id),
              loadingMessage: 'Loading balances...',
              emptyDataIcon: Icons.account_balance_wallet_outlined,
              emptyDataMessage: 'No balance data',
              emptyDataDescription: 'Add expenses to see member balances',
              builder: (context, balances) {
                final sortedEntries = balances.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: _kPadding),
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    return _AnimatedCardWrapper(
                      // Re-use animation wrapper
                      index: index,
                      duration: const Duration(milliseconds: 300),
                      delay: const Duration(milliseconds: 50),
                      child: _buildBalanceListItem(entry, colorScheme,
                          textTheme, outlineBorderSide, cardBorderRadius),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementsTab(ColorScheme colorScheme, TextTheme textTheme,
      BorderSide outlineBorderSide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPadding),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _kPadding, bottom: 12),
                child: Text('Suggested Settlements',
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.2)),
              ),
              Expanded(
                child: _buildFutureContent<Map<String, double>>(
                  // Use generic FutureBuilder helper
                  future: _expenseService.calculateBalances(widget.group.id),
                  loadingMessage: 'Calculating settlements...',
                  builder: (context, balances) {
                    final settlements = _calculateSettlements(balances);
                    if (settlements.isEmpty) {
                      return _buildAllSettledMessage(
                          context, colorScheme, textTheme);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                          bottom: 80), // Add padding for the fixed card
                      itemCount: settlements.length,
                      itemBuilder: (context, index) {
                        final settlement = settlements[index];
                        return _AnimatedCardWrapper(
                          // Re-use animation wrapper
                          index: index,
                          duration: const Duration(milliseconds: 300),
                          delay: const Duration(milliseconds: 50),
                          child: _buildSettlementListItem(settlement,
                              colorScheme, textTheme, outlineBorderSide),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Fixed position instructions card at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: _buildSettlementInstructionsCard(colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  // --- Overview Card Builders ---

  Widget _buildTotalExpensesCard(ColorScheme colorScheme, TextTheme textTheme,
      BorderSide outlineBorderSide, BorderRadius cardBorderRadius) {
    return _AnalysisCard(
      // Use generic card wrapper
      title: 'Total Expenses',
      iconData: Icons.account_balance_wallet_outlined,
      iconColor: colorScheme.primary,
      iconBgColor: colorScheme.primary.withValues(alpha: 0.1),
      outlineBorderSide: outlineBorderSide,
      borderRadius: cardBorderRadius,
      child: _buildFutureContent<double>(
        // Use generic FutureBuilder helper
        future: _calculateTotalExpenses(_expenseService),
        loadingMessage: 'Calculating total...',
        builder: (context, total) {
          return TweenAnimationBuilder<double>(
            // Keep amount animation
            tween: Tween<double>(begin: 0, end: total),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: _kPadding),
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
                    Text(_settingsService.currency,
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

  Widget _buildMonthlyExpensesCard(ColorScheme colorScheme, TextTheme textTheme,
      BorderSide outlineBorderSide, BorderRadius cardBorderRadius) {
    return _AnalysisCard(
      // Use generic card wrapper
      title: 'Monthly Trend',
      iconData: Icons.insert_chart_outlined,
      iconColor: colorScheme.secondary,
      iconBgColor: colorScheme.secondary.withValues(alpha: 0.1),
      outlineBorderSide: outlineBorderSide,
      borderRadius: cardBorderRadius,
      headerWidget: Container(
        // Specific header tag
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
        child: _buildFutureContent<Map<String, double>>(
          // Use generic FutureBuilder helper
          future: _getMonthlyExpenses(_expenseService),
          loadingMessage: 'Loading expense data...',
          emptyDataIcon: Icons.show_chart,
          emptyDataMessage: 'No expense data available',
          emptyDataDescription: 'Start adding expenses to see monthly trends',
          builder: (context, data) {
            final maxY = data.values.isEmpty
                ? 0.0
                : data.values.reduce((max, v) => max > v ? max : v);
            return LineChart(_buildLineChartData(data, maxY, colorScheme,
                textTheme)); // Extracted LineChartData builder
          },
        ),
      ),
    );
  }

  Widget _buildExpenseDistributionCard(
      ColorScheme colorScheme,
      TextTheme textTheme,
      BorderSide outlineBorderSide,
      BorderRadius cardBorderRadius) {
    return _AnalysisCard(
      // Use generic card wrapper
      title: 'Expense Distribution',
      iconData: Icons.pie_chart_outline,
      iconColor: colorScheme.tertiary,
      iconBgColor: colorScheme.tertiary.withValues(alpha: 0.1),
      outlineBorderSide: outlineBorderSide,
      borderRadius: cardBorderRadius,
      headerWidget: Container(
        // Specific header tag
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
            child: _buildFutureContent<Map<String, double>>(
              // Use generic FutureBuilder helper
              future: _expenseService.calculateBalances(widget.group.id),
              loadingMessage: 'Loading distribution data...',
              emptyDataIcon: Icons.pie_chart_outline,
              emptyDataMessage: 'No distribution data',
              emptyDataDescription: 'Add expenses to see member distribution',
              builder: (context, balances) {
                final totalExpenses = balances.values
                    .fold<double>(0, (sum, value) => sum + value.abs());
                if (totalExpenses == 0) {
                  return _buildEmptyDataWidget(
                    // Handle zero total case
                    context,
                    colorScheme.tertiary,
                    Icons.pie_chart_outline,
                    'No expenses to display',
                    'All balances are currently settled',
                  );
                }
                return PieChart(_buildPieChartData(balances, totalExpenses,
                    colorScheme, textTheme)); // Extracted PieChartData builder
              },
            ),
          ),
          const SizedBox(height: _kPadding),
          _buildFutureContent<Map<String, double>>(
            // Use generic FutureBuilder helper for legend
            future: _expenseService.calculateBalances(widget.group.id),
            loadingMessage: '', // No separate loading for legend needed
            showLoadingIndicator: false, // Hide indicator
            builder: (context, balances) {
              if (balances.isEmpty || balances.values.every((v) => v == 0)) {
                return const SizedBox.shrink();
              }
              return _buildPieChartLegend(
                  balances, colorScheme, textTheme); // Extracted Legend builder
            },
          ),
        ],
      ),
    );
  }

  // --- List Item Builders ---

  Widget _buildBalanceListItem(
      MapEntry<String, double> entry,
      ColorScheme colorScheme,
      TextTheme textTheme,
      BorderSide outlineBorderSide,
      BorderRadius cardBorderRadius) {
    final bool isCredit = entry.value >= 0;
    final Color valueColor =
        isCredit ? colorScheme.tertiary : colorScheme.error;
    final Color bgColor = valueColor.withValues(alpha: 0.1);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: cardBorderRadius, side: outlineBorderSide),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // Show a dialog with more details if needed
          final userName = await _userService.getUserName(entry.key);
          if (!mounted) return;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Balance Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: bgColor,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: valueColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCredit ? 'To receive' : 'To pay',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_settingsService.currency}${entry.value.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Avatar with name
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: bgColor,
                    child: FutureBuilder<String>(
                      future: _userService.getUserName(entry.key),
                      builder: (context, snapshot) => Text(
                        snapshot.data?.isNotEmpty == true
                            ? snapshot.data![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: FutureBuilder<String>(
                      future: _userService.getUserName(entry.key),
                      builder: (context, snapshot) => Text(
                        snapshot.data ?? '...',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),

              // Status indicator
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 12,
                            color: valueColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCredit ? 'Receives' : 'Pays',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: valueColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                '${_settingsService.currency}${entry.value.abs().toStringAsFixed(2)}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettlementListItem(
      Settlement settlement,
      ColorScheme colorScheme,
      TextTheme textTheme,
      BorderSide outlineBorderSide) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), side: outlineBorderSide),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            _showSettlementDetailsDialog(settlement, colorScheme, textTheme),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: _kPadding, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment
                .spaceBetween, // Use spaceBetween for alignment
            children: [
              _buildSettlementUser(settlement.from, true, colorScheme,
                  textTheme), // From User (isDebtor = true)
              _buildSettlementArrow(
                  settlement.amount, colorScheme, textTheme), // Arrow & Amount
              _buildSettlementUser(settlement.to, false, colorScheme,
                  textTheme), // To User (isDebtor = false)
            ],
          ),
        ),
      ),
    );
  }

  // --- Chart Data Builders ---

  LineChartData _buildLineChartData(Map<String, double> data, double maxY,
      ColorScheme colorScheme, TextTheme textTheme) {
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
              '${_settingsService.currency}${amount.toStringAsFixed(2)}\n',
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
                  child: Text('${_settingsService.currency}${value.toInt()}',
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

  PieChartData _buildPieChartData(Map<String, double> balances,
      double totalExpenses, ColorScheme colorScheme, TextTheme textTheme) {
    int touchedIndex =
        -1; // State for touch interaction could be added to StatefulWidget if needed

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
            touchedIndex = -1;
            return;
          }
          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
          // });
        },
      ),
      sections: List.generate(balances.length, (index) {
        final entry = balances.entries.elementAt(index);
        final isTouched = index == touchedIndex;
        final double percentage = (entry.value.abs() / totalExpenses) * 100;
        final color = _getDistributionColor(index);
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
          badgeWidget: _buildPieChartBadge(
              entry.key, index, percentage >= 8), // Build badge conditionally
          badgePositionPercentageOffset: 0.8,
        );
      }),
    );
  }

  // --- Helper Widgets ---

  Widget _buildFutureContent<T>({
    required Future<T> future,
    required Widget Function(BuildContext context, T data) builder,
    String loadingMessage = 'Loading...',
    String errorMessage = 'Error loading data',
    String? errorDetails, // Optional: Specific error detail
    IconData? emptyDataIcon,
    String? emptyDataMessage,
    String? emptyDataDescription,
    bool showLoadingIndicator = true, // Control loading indicator visibility
    Color? loadingIndicatorColor, // Allow custom loading color
  }) {
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
                  emptyDataIcon, emptyDataMessage, emptyDataDescription ?? '')
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
        padding: const EdgeInsets.all(_kPadding),
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
        padding: const EdgeInsets.all(_kPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(_kPadding),
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

  Widget _buildAllSettledMessage(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: colorScheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline,
                size: 48, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 24),
          Text('All settled up!',
              style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600, color: colorScheme.primary)),
          const SizedBox(height: 12),
          Text('There are no settlements needed.',
              style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            // Use tonalIcon version
            onPressed: () => setState(() {}), // Refresh state
            icon: Icon(Icons.refresh,
                size: 18, color: colorScheme.onPrimaryContainer),
            label: const Text('Refresh'),
            style: FilledButton.styleFrom(
              backgroundColor:
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
              foregroundColor: colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(
                  horizontal: _kPadding, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementInstructionsCard(
      ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: _kPadding),
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('How to Settle Up',
                  style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: colorScheme.primary)),
            ]),
            const SizedBox(height: 12),
            _buildInstructionStep(textTheme, colorScheme, '1.',
                'Follow the payment directions below (tap for details)'),
            const SizedBox(height: 4),
            _buildInstructionStep(textTheme, colorScheme, '2.',
                'Mark settlements as complete once paid'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(TextTheme textTheme, ColorScheme colorScheme,
      String number, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(number,
          style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold, color: colorScheme.primary)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant))),
    ]);
  }

  Widget _buildUserAvatar(String userId, double radius, Color bgColor,
      Color fgColor, Color shadowColor) {
    return FutureBuilder<String>(
      future: _userService.getUserName(userId),
      builder: (context, snapshot) {
        final name = snapshot.data ?? '?';
        return Container(
          width: radius,
          height: radius,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: shadowColor, blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: fgColor,
                  fontSize: radius * 0.45,
                  fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettlementUser(String userId, bool isDebtor,
      ColorScheme colorScheme, TextTheme textTheme) {
    final color = isDebtor ? colorScheme.error : colorScheme.tertiary;
    final bgColor = color.withValues(alpha: 0.1);
    final fgColor = color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Conditionally add avatar before/after name based on isDebtor
        if (isDebtor) ...[
          _buildUserAvatar(
              userId, 32, bgColor, fgColor, color.withValues(alpha: 0.1)),
          const SizedBox(width: 6),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 70), // Limit name width
          child: FutureBuilder<String>(
            future: _userService.getUserName(userId),
            builder: (context, snapshot) => Text(
              snapshot.data ?? '...',
              style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500, color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
              textAlign: isDebtor ? TextAlign.left : TextAlign.right,
            ),
          ),
        ),
        if (!isDebtor) ...[
          const SizedBox(width: 6),
          _buildUserAvatar(
              userId, 32, bgColor, fgColor, color.withValues(alpha: 0.1)),
        ],
      ],
    );
  }

  Widget _buildSettlementArrow(
      double amount, ColorScheme colorScheme, TextTheme textTheme) {
    return Expanded(
      // Allow arrow section to expand
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.arrow_forward, size: 12, color: colorScheme.primary),
              const SizedBox(width: 2),
              Text('pays',
                  style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500, color: colorScheme.primary)),
            ]),
          ),
          // Removed SizedBox for tighter spacing
          Text(
            '${_settingsService.currency}${amount.toStringAsFixed(2)}',
            style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartLegend(Map<String, double> balances,
      ColorScheme colorScheme, TextTheme textTheme) {
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
            final color = _getDistributionColor(index);
            return FutureBuilder<String>(
              // Fetch name for legend item
              future: _userService.getUserName(entry.key),
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
                          '(${_settingsService.currency}${entry.value.abs().toStringAsFixed(2)})',
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

  Widget _buildPieChartBadge(String userId, int colorIndex, bool showBadge) {
    if (!showBadge) return const SizedBox.shrink(); // Don't build if not shown

    final color = _getDistributionColor(colorIndex);
    return FutureBuilder<String>(
      future: _userService.getUserName(userId),
      builder: (context, snapshot) {
        final name = snapshot.data ?? '?';
        if (name.isEmpty) return const SizedBox.shrink();

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
          child: CircleAvatar(
            // Use CircleAvatar for simplicity
            radius: 8,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.9)),
            ),
          ),
        );
      },
    );
  }

  // --- Data Calculation & Helpers ---

  Future<double> _calculateTotalExpenses(ExpenseService expenseService) async {
    // Simpler calculation using stream's first value and fold
    final expenses =
        await expenseService.getGroupExpenses(widget.group.id).first;
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  Future<Map<String, double>> _getMonthlyExpenses(
      ExpenseService expenseService) async {
    final expenses =
        await expenseService.getGroupExpenses(widget.group.id).first;
    final Map<String, double> monthlyExpenses = {};
    // Use DateFormat consistently
    final monthFormatter = DateFormat('MMM yyyy');
    for (var expense in expenses) {
      final month = monthFormatter.format(expense.date);
      monthlyExpenses.update(month, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }
    // Consider sorting the map by date if needed for the chart
    // Example: return Map.fromEntries(monthlyExpenses.entries.toList()..sort(...));
    return monthlyExpenses;
  }

  Color _getDistributionColor(int index) {
    // Keep distinct colors
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFFC107),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
      Color(0xFFF44336),
      Color(0xFFFF9800),
      Color(0xFF795548),
    ];
    return colors[index % colors.length];
  }

  List<Settlement> _calculateSettlements(Map<String, double> balances) {
    // Simplified settlement algorithm
    final settlements = <Settlement>[];
    if (balances.length < 2) return settlements;

    var debtors = balances.entries
        .where((e) => e.value < -0.01)
        .toList(); // Use tolerance
    var creditors =
        balances.entries.where((e) => e.value > 0.01).toList(); // Use tolerance

    debtors.sort((a, b) =>
        a.value.compareTo(b.value)); // Sort ascending (most negative first)
    creditors.sort((a, b) =>
        b.value.compareTo(a.value)); // Sort descending (largest positive first)

    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      var debtor = debtors[i];
      var creditor = creditors[j];
      double amount = debtor.value
          .abs()
          .clamp(0, creditor.value); // Calculate transferable amount

      if (amount > 0.01) {
        // Check tolerance before adding settlement
        settlements.add(
            Settlement(from: debtor.key, to: creditor.key, amount: amount));

        debtors[i] = MapEntry(debtor.key, debtor.value + amount);
        creditors[j] = MapEntry(creditor.key, creditor.value - amount);
      }

      if (debtors[i].value.abs() < 0.01) i++; // Move to next debtor if settled
      if (creditors[j].value < 0.01) j++; // Move to next creditor if settled
    }
    return settlements;
  }

  // --- Dialogs ---

  void _showInfoDialog(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            Icon(Icons.info_outline, color: colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text('About Expense Analysis',
                style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          ]),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                      context,
                      colorScheme,
                      textTheme,
                      'Overview',
                      'Total expenses, monthly trends, and member expense distribution.',
                      Icons.dashboard_outlined),
                  const SizedBox(height: _kPadding),
                  _buildInfoSection(
                      context,
                      colorScheme,
                      textTheme,
                      'Balances',
                      'How much each member owes or is owed.',
                      Icons.account_balance_wallet_outlined),
                  const SizedBox(height: _kPadding),
                  _buildInfoSection(
                      context,
                      colorScheme,
                      textTheme,
                      'Settlements',
                      'Suggested optimal payments to settle debts.',
                      Icons.swap_horiz_rounded),
                ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              child: const Text('Close'),
            ),
          ],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kRadius)),
          backgroundColor: colorScheme.surface,
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, ColorScheme colorScheme,
      TextTheme textTheme, String title, String description, IconData icon) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: colorScheme.primary, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(description,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
      ])),
    ]);
  }

  void _showSettlementDetailsDialog(
      Settlement settlement, ColorScheme colorScheme, TextTheme textTheme) {
    // Track loading state
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Settlement Details'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('To settle the balance:',
                style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: _kPadding),
            FutureBuilder<List<String>>(
              // Fetch both names
              future: Future.wait([
                _userService.getUserName(settlement.from),
                _userService.getUserName(settlement.to)
              ]),
              builder: (context, namesSnapshot) {
                final fromName = namesSnapshot.data?[0] ?? '...';
                final toName = namesSnapshot.data?[1] ?? '...';
                return Text('$fromName needs to pay $toName',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600));
              },
            ),
            const SizedBox(height: 8),
            Text(
                '${_settingsService.currency}${settlement.amount.toStringAsFixed(2)}',
                style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: colorScheme.primary)),
            const SizedBox(height: _kPadding),
            Text('Once paid, mark this settlement as complete.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
          ]),
          actions: [
            TextButton(
                onPressed: isProcessing
                    ? null // Disable when processing
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Close')),
            FilledButton.tonal(
              onPressed: isProcessing
                  ? null // Disable when processing
                  : () async {
                      // Update loading state
                      setState(() {
                        isProcessing = true;
                      });

                      try {
                        // Call the service to mark as settled
                        final result =
                            await _expenseService.markSettlementAsSettled(
                          widget.group.id,
                          settlement.from,
                          settlement.to,
                          settlement.amount,
                        );

                        // Close the dialog
                        if (mounted && dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }

                        // Show success message
                        if (result != null && mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: colorScheme.onPrimary),
                                  const SizedBox(width: 12),
                                  const Text('Settlement marked as complete!'),
                                ],
                              ),
                              backgroundColor: colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                            ),
                          );

                          // Refresh the screen to update balances
                          if (mounted) {
                            setState(() {});
                            // Force refresh of the parent state to update balances
                            this.setState(() {});
                          }
                        } else if (mounted) {
                          // Show error message
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: colorScheme.onError),
                                  const SizedBox(width: 12),
                                  const Text(
                                      'Failed to mark settlement as complete'),
                                ],
                              ),
                              backgroundColor: colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        // Handle errors
                        if (mounted) {
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: colorScheme.onError),
                                  const SizedBox(width: 12),
                                  Text('Error: ${e.toString()}'),
                                ],
                              ),
                              backgroundColor: colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        // Reset loading state if dialog is still open
                        if (mounted) {
                          setState(() {
                            isProcessing = false;
                          });
                        }
                      }
                    },
              child: isProcessing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Processing...'),
                      ],
                    )
                  : const Text('Mark as Settled'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Extracted Helper Widgets ---

// Generic Card Wrapper
class _AnalysisCard extends StatelessWidget {
  final String title;
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final Widget? headerWidget; // Optional widget for top-right corner
  final Widget child;
  final BorderSide outlineBorderSide;
  final BorderRadius borderRadius;

  const _AnalysisCard({
    required this.title,
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    this.headerWidget,
    required this.child,
    required this.outlineBorderSide,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
          borderRadius: borderRadius, side: outlineBorderSide),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withValues(alpha: 0.95)
            ],
          ),
        ),
        padding: const EdgeInsets.all(_kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: iconColor.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Icon(iconData, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                ]),
                if (headerWidget != null) headerWidget!,
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

// Animation Wrapper for List Items
class _AnimatedCardWrapper extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double verticalOffset;

  const _AnimatedCardWrapper({
    required this.index,
    required this.child,
    this.duration = _kCardAnimDuration, // Default duration
    this.delay = const Duration(milliseconds: 100), // Default delay increment
    this.verticalOffset = 20.0, // Default offset
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration + (delay * index), // Staggered animation
      curve: Curves.easeOutQuad,
      builder: (context, value, buildChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, verticalOffset * (1 - value)),
            child: buildChild,
          ),
        );
      },
      child: child,
    );
  }
}

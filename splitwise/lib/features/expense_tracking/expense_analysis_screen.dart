import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:splitwise/utils/app_color.dart';
import 'package:intl/intl.dart';

class ExpenseAnalysisScreen extends StatefulWidget {
  final Group group;
  const ExpenseAnalysisScreen({super.key, required this.group});

  @override
  _ExpenseAnalysisScreenState createState() => _ExpenseAnalysisScreenState();
}

class _ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        setState(() => _selectedTabIndex = _tabController.index);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);
    final expenseService = Provider.of<ExpenseService>(context);
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Expense Analysis',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.textMain,
              indicatorWeight: 3,
              labelColor: AppColors.textMain,
              unselectedLabelColor: AppColors.textLight,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Balances'),
                Tab(text: 'Settlements'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(expenseService, settingsService, userService),
          _buildBalancesTab(expenseService, settingsService, userService),
          _buildSettlementsTab(expenseService, settingsService, userService),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ExpenseService expenseService,
      SettingsService settingsService, UserService userService) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _buildTotalExpensesCard(expenseService, settingsService),
        const SizedBox(height: 24),
        _buildMonthlyExpensesCard(expenseService, settingsService),
        const SizedBox(height: 24),
        _buildExpenseDistributionCard(
            expenseService, settingsService, userService),
      ],
    );
  }

  Widget _buildTotalExpensesCard(
      ExpenseService expenseService, SettingsService settingsService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryMain.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primaryMain,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Total Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<double>(
            future: _calculateTotalExpenses(expenseService),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
                    ),
                  ),
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    settingsService.currency,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormat('#,##0.00').format(snapshot.data!),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyExpensesCard(
      ExpenseService expenseService, SettingsService settingsService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryMain.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insert_chart_outlined,
                  color: AppColors.primaryMain,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Monthly Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: FutureBuilder<Map<String, double>>(
              future: _getMonthlyExpenses(expenseService),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
                    ),
                  );
                }

                final data = snapshot.data!;
                final maxY = data.values
                    .reduce((max, value) => max > value ? max : value);

                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final months = data.keys.toList();
                            if (value >= 0 && value < months.length) {
                              return Text(months[value.toInt()].substring(0, 3),
                                  style: const TextStyle(
                                    color: AppColors.textMain,
                                    fontSize: 12,
                                  ));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: data.length.toDouble() - 1,
                    minY: 0,
                    maxY: maxY * 1.2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: data.entries.map((e) {
                          return FlSpot(
                            data.keys.toList().indexOf(e.key).toDouble(),
                            e.value,
                          );
                        }).toList(),
                        isCurved: true,
                        color: AppColors.primaryMain,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryMain.withValues(alpha: 0.2),
                              AppColors.primaryMain.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseDistributionCard(
    ExpenseService expenseService,
    SettingsService settingsService,
    UserService userService,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryMain.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_outline,
                  color: AppColors.primaryMain,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.3,
            child: FutureBuilder<Map<String, double>>(
              future: expenseService.calculateBalances(widget.group.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
                    ),
                  );
                }

                final balances = snapshot.data!;
                final totalExpenses = balances.values.fold<double>(
                  0,
                  (sum, value) => sum + value.abs(),
                );

                return PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: balances.entries.map((entry) {
                      final double percentage =
                          (entry.value.abs() / totalExpenses) * 100;
                      return PieChartSectionData(
                        color: _getDistributionColor(
                          balances.keys.toList().indexOf(entry.key),
                        ),
                        value: entry.value.abs(),
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 100,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, double>>(
            future: expenseService.calculateBalances(widget.group.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: snapshot.data!.entries.map((entry) {
                  return FutureBuilder<String>(
                    future: userService.getUserName(entry.key),
                    builder: (context, nameSnapshot) {
                      final userName = nameSnapshot.data ?? 'Loading...';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDistributionColor(
                            snapshot.data!.keys.toList().indexOf(entry.key),
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getDistributionColor(
                                  snapshot.data!.keys
                                      .toList()
                                      .indexOf(entry.key),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textMain,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesTab(
    ExpenseService expenseService,
    SettingsService settingsService,
    UserService userService,
  ) {
    return FutureBuilder<Map<String, double>>(
      future: expenseService.calculateBalances(widget.group.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
            ),
          );
        }

        final balances = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: balances.length,
          itemBuilder: (context, index) {
            final entry = balances.entries.elementAt(index);
            return FutureBuilder<String>(
              future: userService.getUserName(entry.key),
              builder: (context, userSnapshot) {
                final userName = userSnapshot.data ?? 'Loading...';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMain.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMain.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.primaryMain,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    subtitle: Text(
                      entry.value >= 0 ? 'To receive' : 'To pay',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${settingsService.currency}${entry.value.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: entry.value >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (entry.value >= 0
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.value >= 0 ? 'Credit' : 'Debit',
                            style: TextStyle(
                              fontSize: 12,
                              color: entry.value >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSettlementsTab(
    ExpenseService expenseService,
    SettingsService settingsService,
    UserService userService,
  ) {
    return FutureBuilder<Map<String, double>>(
      future: expenseService.calculateBalances(widget.group.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
            ),
          );
        }

        final balances = snapshot.data!;
        final settlements = _calculateSettlements(balances);

        if (settlements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.success,
                ),
                SizedBox(height: 16),
                Text(
                  'All settled up!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No payments needed',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: settlements.length,
          itemBuilder: (context, index) {
            final settlement = settlements[index];
            return FutureBuilder<List<String>>(
              future: Future.wait([
                userService.getUserName(settlement.from),
                userService.getUserName(settlement.to),
              ]),
              builder: (context, namesSnapshot) {
                final fromName = namesSnapshot.data?[0] ?? 'Loading...';
                final toName = namesSnapshot.data?[1] ?? 'Loading...';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMain.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryMain
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.swap_horiz_rounded,
                                color: AppColors.primaryMain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Settlement',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${settingsService.currency}${settlement.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryMain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'From',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fromName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              color: AppColors.primaryMain,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'To',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    toName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<double> _calculateTotalExpenses(ExpenseService expenseService) async {
    final expenses =
        await expenseService.getGroupExpenses(widget.group.id).first;
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  Future<Map<String, double>> _getMonthlyExpenses(
      ExpenseService expenseService) async {
    final expenses =
        await expenseService.getGroupExpenses(widget.group.id).first;
    final Map<String, double> monthlyExpenses = {};

    for (var expense in expenses) {
      final month = DateFormat('MMM yyyy').format(expense.date);
      monthlyExpenses[month] = (monthlyExpenses[month] ?? 0) + expense.amount;
    }

    return monthlyExpenses;
  }

  Color _getDistributionColor(int index) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    return colors[index % colors.length];
  }

  List<Settlement> _calculateSettlements(Map<String, double> balances) {
    final List<Settlement> settlements = [];
    final List<MapEntry<String, double>> sortedBalances =
        balances.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    var i = 0;
    var j = sortedBalances.length - 1;

    while (i < j) {
      final creditor = sortedBalances[i];
      final debtor = sortedBalances[j];

      if (creditor.value <= 0 || debtor.value >= 0) break;

      final amount = creditor.value.abs() < debtor.value.abs()
          ? creditor.value.abs()
          : debtor.value.abs();

      settlements.add(Settlement(
        from: debtor.key,
        to: creditor.key,
        amount: amount,
      ));

      sortedBalances[i] = MapEntry(creditor.key, creditor.value - amount);
      sortedBalances[j] = MapEntry(debtor.key, debtor.value + amount);

      if (sortedBalances[i].value <= 0) i++;
      if (sortedBalances[j].value >= 0) j--;
    }

    return settlements;
  }
}

class Settlement {
  final String from;
  final String to;
  final double amount;

  Settlement({
    required this.from,
    required this.to,
    required this.amount,
  });
}

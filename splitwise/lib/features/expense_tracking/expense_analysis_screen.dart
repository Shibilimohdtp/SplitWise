import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:splitwise/utils/app_color.dart';
import 'package:intl/intl.dart';

class ExpenseAnalysisScreen extends StatelessWidget {
  final Group group;

  ExpenseAnalysisScreen({required this.group});

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);
    final expenseService = Provider.of<ExpenseService>(context);
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Expense Analysis',
                  style: TextStyle(color: AppColors.backgroundLight)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryMain, AppColors.primaryLight],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.analytics,
                      size: 80, color: AppColors.backgroundLight),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _TotalExpensesCard(
              group: group,
              expenseService: expenseService,
              settingsService: settingsService,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Expense Distribution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _ExpenseDistributionChart(
              group: group,
              expenseService: expenseService,
              settingsService: settingsService,
              userService: userService,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Balances',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _BalancesTab(
              group: group,
              expenseService: expenseService,
              settingsService: settingsService,
              userService: userService,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Suggested Settlements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SettlementsTab(
              group: group,
              expenseService: expenseService,
              settingsService: settingsService,
              userService: userService,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalExpensesCard extends StatelessWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;

  _TotalExpensesCard({
    required this.group,
    required this.expenseService,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.backgroundLight,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Group Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            SizedBox(height: 8),
            FutureBuilder<double>(
              future: _calculateTotalExpenses(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    '${settingsService.currency}${NumberFormat('#,##0.00').format(snapshot.data!)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMain,
                    ),
                  );
                } else {
                  return CircularProgressIndicator(
                      color: AppColors.primaryMain);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<double> _calculateTotalExpenses() async {
    final expenses = await expenseService.getGroupExpenses(group.id).first;
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }
}

class _ExpenseDistributionChart extends StatelessWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;
  final UserService userService;

  _ExpenseDistributionChart({
    required this.group,
    required this.expenseService,
    required this.settingsService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: expenseService.calculateBalances(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primaryMain));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: AppColors.textMain)));
        }

        final balances = snapshot.data!;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: AppColors.backgroundLight,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.3,
                  child: PieChart(
                    PieChartData(
                      sections: _generatePieChartSections(balances),
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildLegend(balances),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _generatePieChartSections(
      Map<String, double> balances) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return balances.entries.map((entry) {
      final amount = entry.value.abs();
      final color =
          colors[balances.keys.toList().indexOf(entry.key) % colors.length];
      return PieChartSectionData(
        color: color,
        value: amount,
        title: '',
        radius: 100,
        titleStyle: TextStyle(fontSize: 0),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, double> balances) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: balances.entries.map((entry) {
        final color =
            colors[balances.keys.toList().indexOf(entry.key) % colors.length];
        return FutureBuilder<String>(
          future: userService.getUserName(entry.key),
          builder: (context, snapshot) {
            final userName = snapshot.data ?? 'Loading...';
            return Chip(
              avatar: CircleAvatar(backgroundColor: color),
              label: Text(
                '$userName: ${settingsService.currency}${entry.value.abs().toStringAsFixed(2)}',
                style: TextStyle(color: AppColors.textMain, fontSize: 12),
              ),
              backgroundColor: AppColors.backgroundLight,
            );
          },
        );
      }).toList(),
    );
  }
}

class _BalancesTab extends StatelessWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;
  final UserService userService;

  _BalancesTab({
    required this.group,
    required this.expenseService,
    required this.settingsService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: expenseService.calculateBalances(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primaryMain));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: AppColors.textMain)));
        }

        final balances = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: balances.length,
          itemBuilder: (context, index) {
            final entry = balances.entries.elementAt(index);
            return FutureBuilder<String>(
              future: userService.getUserName(entry.key),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                      title: Text('Loading...',
                          style: TextStyle(color: AppColors.textLight)));
                }
                final userName = userSnapshot.data ?? 'Unknown';
                final amount = entry.value;
                final color = amount >= 0 ? Colors.green : Colors.red;
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: AppColors.backgroundLight,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(userName[0],
                          style: TextStyle(color: AppColors.backgroundLight)),
                      backgroundColor: AppColors.primaryMain,
                    ),
                    title: Text(userName,
                        style: TextStyle(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.bold)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${settingsService.currency}${amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          amount >= 0 ? 'to receive' : 'to pay',
                          style: TextStyle(
                              color: AppColors.textLight, fontSize: 12),
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
}

class _SettlementsTab extends StatelessWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;
  final UserService userService;

  _SettlementsTab({
    required this.group,
    required this.expenseService,
    required this.settingsService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: expenseService.calculateBalances(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primaryMain));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: AppColors.textMain)));
        }

        final balances = snapshot.data!;

        return FutureBuilder<List<Widget>>(
          future: _generateSettlementSuggestions(
              balances, settingsService, userService),
          builder: (context, suggestionsSnapshot) {
            if (suggestionsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryMain));
            }

            if (suggestionsSnapshot.hasError) {
              return Center(
                  child: Text('Error: ${suggestionsSnapshot.error}',
                      style: TextStyle(color: AppColors.textMain)));
            }

            return Column(
              children: suggestionsSnapshot.data!,
            );
          },
        );
      },
    );
  }

  Future<List<Widget>> _generateSettlementSuggestions(
    Map<String, double> balances,
    SettingsService settingsService,
    UserService userService,
  ) async {
    final List<MapEntry<String, double>> sortedBalances =
        balances.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final suggestions = <Widget>[];
    var i = 0;
    var j = sortedBalances.length - 1;

    while (i < j) {
      final payer = sortedBalances[j];
      final receiver = sortedBalances[i];

      if (payer.value.abs() < 0.01)
        break; // Stop if remaining amounts are negligible

      final amount = min(-payer.value, receiver.value);
      final payerName = await userService.getUserName(payer.key);
      final receiverName = await userService.getUserName(receiver.key);

      suggestions.add(Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.backgroundLight,
        child: ListTile(
          leading: Icon(Icons.swap_horiz, color: AppColors.primaryMain),
          title: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 16, color: AppColors.textMain),
              children: [
                TextSpan(
                    text: payerName,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: ' pays '),
                TextSpan(
                    text: receiverName,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          trailing: Text(
            '${settingsService.currency}${amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: AppColors.primaryDark, fontWeight: FontWeight.bold),
          ),
        ),
      ));

      sortedBalances[i] = MapEntry(receiver.key, receiver.value - amount);
      sortedBalances[j] = MapEntry(payer.key, payer.value + amount);

      if (sortedBalances[i].value < 0.01) i++;
      if (sortedBalances[j].value > -0.01) j--;
    }

    return suggestions;
  }
}

double min(double a, double b) => a < b ? a : b;

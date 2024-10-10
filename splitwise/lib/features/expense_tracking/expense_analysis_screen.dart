import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseAnalysisScreen extends StatelessWidget {
  final Group group;

  ExpenseAnalysisScreen({required this.group});

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);
    final expenseService = Provider.of<ExpenseService>(context);
    final userService = Provider.of<UserService>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Expense Analysis'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pie_chart), text: 'Overview'),
              Tab(icon: Icon(Icons.list), text: 'Balances'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'Settlements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
                group: group,
                expenseService: expenseService,
                settingsService: settingsService),
            _BalancesTab(
                group: group,
                expenseService: expenseService,
                settingsService: settingsService,
                userService: userService),
            _SettlementsTab(
                group: group,
                expenseService: expenseService,
                settingsService: settingsService,
                userService: userService),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;

  _OverviewTab(
      {required this.group,
      required this.expenseService,
      required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: expenseService.calculateBalances(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final balances = snapshot.data!;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TotalExpensesCard(
                  group: group,
                  expenseService: expenseService,
                  settingsService: settingsService),
              SizedBox(height: 16),
              _ExpenseDistributionChart(
                  balances: balances, settingsService: settingsService),
            ],
          ),
        );
      },
    );
  }
}

class _BalancesTab extends StatelessWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;
  final UserService userService;

  _BalancesTab(
      {required this.group,
      required this.expenseService,
      required this.settingsService,
      required this.userService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: expenseService.calculateBalances(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final balances = snapshot.data!;

        return ListView.builder(
          itemCount: balances.length,
          itemBuilder: (context, index) {
            final entry = balances.entries.elementAt(index);
            return FutureBuilder<String>(
              future: userService.getUserName(entry.key),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(title: Text('Loading...'));
                }
                final userName = userSnapshot.data ?? 'Unknown';
                final amount = entry.value;
                final color = amount >= 0 ? Colors.green : Colors.red;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(userName[0])),
                    title: Text(userName),
                    trailing: Text(
                      '${settingsService.currency}${amount.abs().toStringAsFixed(2)}',
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(amount >= 0 ? 'to receive' : 'to pay'),
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

  _SettlementsTab(
      {required this.group,
      required this.expenseService,
      required this.settingsService,
      required this.userService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: expenseService.calculateBalances(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final balances = snapshot.data!;

        return FutureBuilder<List<Widget>>(
          future: _generateSettlementSuggestions(
              balances, settingsService, userService),
          builder: (context, suggestionsSnapshot) {
            if (suggestionsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (suggestionsSnapshot.hasError) {
              return Center(child: Text('Error: ${suggestionsSnapshot.error}'));
            }

            return ListView(
              padding: EdgeInsets.all(16),
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
      UserService userService) async {
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
        child: ListTile(
          leading: Icon(Icons.swap_horiz),
          title: Text('$payerName pays $receiverName'),
          trailing:
              Text('${settingsService.currency}${amount.toStringAsFixed(2)}'),
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

class _TotalExpensesCard extends StatelessWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;

  _TotalExpensesCard(
      {required this.group,
      required this.expenseService,
      required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Group Expenses',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            FutureBuilder<double>(
              future: _calculateTotalExpenses(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    '${settingsService.currency}${snapshot.data!.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Theme.of(context).primaryColor),
                  );
                } else {
                  return CircularProgressIndicator();
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
  final Map<String, double> balances;
  final SettingsService settingsService;

  _ExpenseDistributionChart(
      {required this.balances, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expense Distribution',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  sections: _generatePieChartSections(),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    return balances.entries.map((entry) {
      final amount = entry.value.abs();
      final color =
          colors[balances.keys.toList().indexOf(entry.key) % colors.length];
      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${settingsService.currency}${amount.toStringAsFixed(0)}',
        radius: 100,
        titleStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}

double min(double a, double b) => a < b ? a : b;

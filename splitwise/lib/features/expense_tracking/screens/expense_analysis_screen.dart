import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/models/expense.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseAnalysisScreen extends StatelessWidget {
  final Group group;

  ExpenseAnalysisScreen({required this.group});

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);
    final expenseService = ExpenseService(settingsService);

    return Scaffold(
      appBar: AppBar(title: Text('Expense Analysis')),
      body: FutureBuilder<Map<String, double>>(
        future: expenseService.calculateBalances(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final balances = snapshot.data!;

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Text('Total Group Expenses',
                  style: Theme.of(context).textTheme.headlineSmall),
              FutureBuilder<double>(
                future: _calculateTotalExpenses(expenseService),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                        '${settingsService.currency}${snapshot.data!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge);
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
              SizedBox(height: 24),
              Text('Expense Distribution',
                  style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections:
                        _generatePieChartSections(balances, settingsService),
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text('Individual Contributions',
                  style: Theme.of(context).textTheme.headlineSmall),
              ...balances.entries.map((entry) {
                final amount = entry.value;
                final color = amount >= 0 ? Colors.green : Colors.red;
                return ListTile(
                  title: Text(
                      entry.key), // Ideally, show user's name instead of ID
                  trailing: Text(
                    '${settingsService.currency}${amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(amount >= 0 ? 'to receive' : 'to pay'),
                );
              }),
              SizedBox(height: 24),
              Text('Settlement Suggestions',
                  style: Theme.of(context).textTheme.headlineSmall),
              ..._generateSettlementSuggestions(balances, settingsService),
            ],
          );
        },
      ),
    );
  }

  Future<double> _calculateTotalExpenses(ExpenseService expenseService) async {
    final expenses = await expenseService.getGroupExpenses(group.id).first;
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  List<Widget> _generateSettlementSuggestions(
      Map<String, double> balances, SettingsService settingsService) {
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
      suggestions.add(ListTile(
        title: Text('${payer.key} pays ${receiver.key}'),
        trailing:
            Text('${settingsService.currency}${amount.toStringAsFixed(2)}'),
      ));

      sortedBalances[i] = MapEntry(receiver.key, receiver.value - amount);
      sortedBalances[j] = MapEntry(payer.key, payer.value + amount);

      if (sortedBalances[i].value < 0.01) i++;
      if (sortedBalances[j].value > -0.01) j--;
    }

    return suggestions;
  }

  List<PieChartSectionData> _generatePieChartSections(
      Map<String, double> balances, SettingsService settingsService) {
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
        title:
            '${entry.key}\n${settingsService.currency}${amount.toStringAsFixed(2)}',
        radius: 100,
        titleStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}

double min(double a, double b) => a < b ? a : b;

import 'package:flutter/material.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:splitwise/services/settings_service.dart';

class ExpenseList extends StatelessWidget {
  final String groupId;
  final Function(String) onDeleteExpense;

  ExpenseList({required this.groupId, required this.onDeleteExpense});

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    final expenseService = ExpenseService(settingsService);

    return StreamBuilder<List<Expense>>(
      stream: expenseService.getGroupExpenses(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No expenses found.'));
        }

        final expenses = snapshot.data!;

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return Dismissible(
              key: Key(expense.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                onDeleteExpense(expense.id);
              },
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(expense.description),
                  subtitle:
                      Text(DateFormat('MMM d, yyyy').format(expense.date)),
                  trailing: Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:splitwise/services/expense_service.dart';

// --- Constants ---
const double kPadding = 16.0;
const double kRadius = 16.0;
const Duration kAnimDuration = Duration(milliseconds: 300);
const Duration kCardAnimDuration = Duration(milliseconds: 400);

// --- Helper Classes ---
class Settlement {
  final String from;
  final String to;
  final double amount;

  Settlement({required this.from, required this.to, required this.amount});
}

// --- Utility Functions ---
Future<double> calculateTotalExpenses(
    ExpenseService expenseService, String groupId) async {
  // Simpler calculation using stream's first value and fold
  final expenses = await expenseService.getGroupExpenses(groupId).first;
  return expenses.fold<double>(0.0, (sum, expense) {
    // Exclude settlement transactions from total expenses
    if (expense.category == 'Settlement') {
      return sum; // Skip settlement transactions
    }
    return sum + expense.amount;
  });
}

Color getDistributionColor(int index) {
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

List<Settlement> calculateSettlements(Map<String, double> balances) {
  // Simplified settlement algorithm
  final settlements = <Settlement>[];
  if (balances.length < 2) return settlements;

  var debtors =
      balances.entries.where((e) => e.value < -0.01).toList(); // Use tolerance
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
      settlements
          .add(Settlement(from: debtor.key, to: creditor.key, amount: amount));

      debtors[i] = MapEntry(debtor.key, debtor.value + amount);
      creditors[j] = MapEntry(creditor.key, creditor.value - amount);
    }

    if (debtors[i].value.abs() < 0.01) i++; // Move to next debtor if settled
    if (creditors[j].value < 0.01) j++; // Move to next creditor if settled
  }
  return settlements;
}

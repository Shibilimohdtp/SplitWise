import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/database_helper.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:splitwise/services/notification_service.dart';
import 'package:splitwise/services/settings_service.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();
  final SettingsService _settingsService;

  ExpenseService(this._settingsService);

  Future<Expense> addExpense(Expense expense) async {
    final bool hasConnection = await InternetConnectionChecker().hasConnection;
    late Expense newExpense;

    // Convert the amount to the selected currency
    final convertedAmount = await _convertCurrency(
        expense.amount, expense.currency, _settingsService.currency);
    final convertedExpense = expense.copyWith(
        amount: convertedAmount, currency: _settingsService.currency);

    if (!hasConnection) {
      // Offline: Save to local database
      final localId = await _databaseHelper.insertExpense(convertedExpense);
      newExpense = convertedExpense.copyWith(id: localId);
    } else {
      // Online: Save to Firestore
      final docRef =
          await _firestore.collection('expenses').add(convertedExpense.toMap());
      newExpense = convertedExpense.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      // Get group members
      final groupDoc =
          await _firestore.collection('groups').doc(expense.groupId).get();
      final members = List<String>.from(groupDoc.data()?['members'] ?? []);

      // Send notifications to group members
      for (String memberId in members) {
        if (memberId != expense.payerId) {
          await _notificationService.sendNotification(
            memberId,
            'New Expense Added',
            '${expense.description} - ${_settingsService.currency}${convertedAmount.toStringAsFixed(2)}',
            groupId: expense.groupId,
          );
        }
      }
    }

    return newExpense;
  }

  Stream<List<Expense>> getGroupExpenses(String groupId) {
    return _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  Future<void> updateExpense(Expense expense) async {
    await _firestore
        .collection('expenses')
        .doc(expense.id)
        .update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }

  Future<Map<String, double>> calculateBalances(String groupId) async {
    final expenses = await _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();

    Map<String, double> balances = {};

    for (var doc in expenses.docs) {
      final expense = Expense.fromFirestore(doc);
      balances[expense.payerId] =
          (balances[expense.payerId] ?? 0) + expense.amount;

      expense.splitDetails.forEach((userId, amount) {
        balances[userId] = (balances[userId] ?? 0) - amount;
      });
    }

    return balances;
  }

  Future<void> syncOfflineExpenses() async {
    final offlineExpenses = await _databaseHelper.getOfflineExpenses();
    for (var expense in offlineExpenses) {
      await _firestore.collection('expenses').add(expense.toMap());
      await _databaseHelper.deleteExpense(expense.id);
    }
  }

  Future<double> _convertCurrency(
      double amount, String fromCurrency, String toCurrency) async {
    // Implement currency conversion logic here
    // For simplicity, we'll just return the original amount
    // In a real app, you would use an API to get current exchange rates
    return amount;
  }
}

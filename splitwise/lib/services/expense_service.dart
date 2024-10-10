import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/database_helper.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:splitwise/services/notification_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();
  final SettingsService _settingsService;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ExpenseService(this._settingsService);

  Future<Expense> addExpense(Expense expense, {File? receiptImage}) async {
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
      String? receiptUrl;
      if (receiptImage != null) {
        receiptUrl =
            await _uploadReceiptImage(receiptImage, convertedExpense.id);
      }
      final expenseWithReceipt =
          convertedExpense.copyWith(receiptUrl: receiptUrl);
      final docRef = await _firestore
          .collection('expenses')
          .add(expenseWithReceipt.toMap());
      newExpense = expenseWithReceipt.copyWith(id: docRef.id);
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

  Future<String> _uploadReceiptImage(File image, String expenseId) async {
    final ref = _storage.ref().child('receipts/$expenseId.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Stream<List<Expense>> getGroupExpenses(String groupId,
      {String? category,
      DateTime? startDate,
      DateTime? endDate,
      String? memberId}) {
    Query query = _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query =
          query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (memberId != null) {
      query = query.where('payerId', isEqualTo: memberId);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  Future<double> calculateGroupBalance(String groupId, String userId) async {
    final expenses = await _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();

    double balance = 0;

    for (var doc in expenses.docs) {
      final expense = Expense.fromFirestore(doc);
      if (expense.payerId == userId) {
        balance += expense.amount;
      }
      if (expense.splitDetails.containsKey(userId)) {
        balance -= expense.splitDetails[userId]!;
      }
    }

    return balance;
  }

  Future<Map<String, double>> calculateOverallBalance(String userId) async {
    final userGroups = await _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    double totalOwed = 0;
    double totalOwing = 0;

    for (var groupDoc in userGroups.docs) {
      final groupId = groupDoc.id;
      final groupBalance = await calculateBalances(groupId);
      final userBalance = groupBalance[userId] ?? 0;

      if (userBalance > 0) {
        totalOwed += userBalance;
      } else {
        totalOwing += userBalance.abs();
      }
    }

    return {
      'owed': totalOwed,
      'owing': totalOwing,
    };
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

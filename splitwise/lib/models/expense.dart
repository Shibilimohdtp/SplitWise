import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String groupId;
  final String payerId;
  final double amount;
  final String currency;
  final String description;
  final DateTime date;
  final Map<String, double> splitDetails;

  Expense({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.amount,
    required this.currency,
    required this.description,
    required this.date,
    required this.splitDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'payerId': payerId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'date': Timestamp.fromDate(date),
      'splitDetails': jsonEncode(splitDetails),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      groupId: map['groupId'],
      payerId: map['payerId'],
      amount: map['amount'],
      currency: map['currency'],
      description: map['description'],
      date: _parseDate(map['date']),
      splitDetails: Map<String, double>.from(jsonDecode(map['splitDetails'])),
    );
  }

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      payerId: data['payerId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      description: data['description'] ?? '',
      date: _parseDate(data['date']),
      splitDetails:
          Map<String, double>.from(jsonDecode(data['splitDetails'] ?? '{}')),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is int) {
      return DateTime.fromMillisecondsSinceEpoch(date);
    } else {
      return DateTime.now();
    }
  }

  Expense copyWith({
    String? id,
    String? groupId,
    String? payerId,
    double? amount,
    String? currency,
    String? description,
    DateTime? date,
    Map<String, double>? splitDetails,
  }) {
    return Expense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      payerId: payerId ?? this.payerId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      date: date ?? this.date,
      splitDetails: splitDetails ?? this.splitDetails,
    );
  }
}

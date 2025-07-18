import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:splitwise/models/expense.dart';
import 'package:intl/intl.dart';
import 'package:splitwise/services/auth_service.dart';

class ExportService {
  final ExpenseService _expenseService;
  final UserService _userService;
  final SettingsService _settingsService;
  final AuthService _authService;

  ExportService(this._expenseService, this._userService, this._settingsService,
      this._authService);

  Future<String> exportExpenseAnalysis(
      Group group, BuildContext context) async {
    final pdf = pw.Document();
    final ttf = pw.Font.helvetica();
    final expenses = await _expenseService.getGroupExpenses(group.id).first;
    final totalExpenses = expenses.fold<double>(0.0, (sum, expense) {
      if (expense.category == 'Settlement') {
        return sum;
      }
      return sum + expense.amount;
    });
    final balances = await _expenseService.calculateBalances(group.id);
    final userNames =
        await _userService.getUserNamesMap(balances.keys.toList());
    final currentUser = _authService.currentUser;
    final currentUserId = currentUser?.uid;
    final expenseSplits = await Future.wait(expenses
        .map((expense) => _expenseService.getExpenseSplits(expense.id)));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context pdfContext) => [
          _buildTitle(group, ttf),
          pw.SizedBox(height: 30),
          _buildSummarySection(
              totalExpenses, balances, userNames, currentUserId, ttf),
          pw.SizedBox(height: 30),
          _buildTransactionList(expenses, userNames, ttf),
          pw.SizedBox(height: 30),
          _buildExpenseSplits(expenses, expenseSplits, userNames, ttf),
          pw.SizedBox(height: 30),
          _buildBalances(balances, userNames, ttf),
          pw.SizedBox(height: 30),
          _buildSettlements(balances, userNames, ttf),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        "${output.path}/expense_analysis_${group.id}_$timestamp.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  pw.Widget _buildTitle(Group group, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Analysis',
          style: pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF2D3748),
          ),
        ),
        pw.Text(
          'Detailed Report',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF4A5568),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 2,
          width: 100,
          color: const PdfColor.fromInt(0xFF4299E1),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Group Name',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColor.fromInt(0xFF718096),
                  ),
                ),
                pw.Text(
                  group.name,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF2D3748),
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Generated On',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColor.fromInt(0xFF718096),
                  ),
                ),
                pw.Text(
                  DateFormat('MMMM d, y').format(DateTime.now()),
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColor.fromInt(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSummarySection(
      double totalExpenses,
      Map<String, double> balances,
      Map<String, String> userNames,
      String? currentUserId,
      pw.Font ttf) {
    final userBalance = balances[currentUserId] ?? 0.0;
    final youOwe = userBalance < 0 ? userBalance.abs() : 0.0;
    final youAreOwed = userBalance > 0 ? userBalance : 0.0;

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF7FAFC),
        borderRadius: pw.BorderRadius.circular(12),
        border:
            pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 1),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Financial Summary',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF2D3748),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryCard(
                  'Total Expenses',
                  '${_settingsService.currency}${totalExpenses.toStringAsFixed(2)}',
                  const PdfColor.fromInt(0xFF4299E1),
                  ttf,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildSummaryCard(
                  'You Owe',
                  '${_settingsService.currency}${youOwe.toStringAsFixed(2)}',
                  const PdfColor.fromInt(0xFFF56565),
                  ttf,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildSummaryCard(
                  'You Are Owed',
                  '${_settingsService.currency}${youAreOwed.toStringAsFixed(2)}',
                  const PdfColor.fromInt(0xFF48BB78),
                  ttf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard(
      String title, String value, PdfColor color, pw.Font ttf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFFFF),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 12,
              color: const PdfColor.fromInt(0xFF718096),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionList(
      List<Expense> expenses, Map<String, String> userNames, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction History',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF2D3748),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF4299E1),
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          headerHeight: 25,
          cellHeight: 30,
          headers: ['Date', 'Description', 'Payer', 'Amount'],
          data: expenses
              .map((e) => [
                    DateFormat('MMM d, y').format(e.date),
                    e.description,
                    userNames[e.payerId] ?? 'Unknown',
                    '${_settingsService.currency}${e.amount.toStringAsFixed(2)}',
                  ])
              .toList(),
          border: null,
          headerStyle: pw.TextStyle(
            color: const PdfColor.fromInt(0xFFFFFFFF),
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
          ),
          cellStyle: const pw.TextStyle(
            color: PdfColor.fromInt(0xFF4A5568),
            fontSize: 11,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
          },
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  pw.Widget _buildExpenseSplits(
      List<Expense> expenses,
      List<Map<String, dynamic>> expenseSplits,
      Map<String, String> userNames,
      pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Breakdown',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF2D3748),
          ),
        ),
        pw.SizedBox(height: 12),
        ...List.generate(expenses.length, (index) {
          final expense = expenses[index];
          final splits = expenseSplits[index];
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF7FAFC),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      expense.description,
                      style: pw.TextStyle(
                        font: ttf,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                        color: const PdfColor.fromInt(0xFF2D3748),
                      ),
                    ),
                    pw.Text(
                      DateFormat('MMM d, y').format(expense.date),
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        color: const PdfColor.fromInt(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEDF2F7),
                ),
                headerHeight: 20,
                cellHeight: 25,
                headers: ['Member', 'Share', 'Paid', 'Owes'],
                data: splits.entries.map((entry) {
                  final userId = entry.key;
                  final split = entry.value;
                  return [
                    userNames[userId] ?? 'Unknown',
                    '${_settingsService.currency}${split['share']?.toStringAsFixed(2) ?? '0.00'}',
                    '${_settingsService.currency}${split['paid']?.toStringAsFixed(2) ?? '0.00'}',
                    '${_settingsService.currency}${split['owes']?.toStringAsFixed(2) ?? '0.00'}',
                  ];
                }).toList(),
                border: null,
                headerStyle: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF4A5568),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
                cellStyle: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFF4A5568),
                  fontSize: 10,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 20),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildBalances(Map<String, double> balances,
      Map<String, String> userNames, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Current Balances',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF2D3748),
          ),
        ),
        pw.SizedBox(height: 12),
        // ignore: deprecated_member_use
        pw.Table.fromTextArray(
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF4299E1),
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          headerHeight: 25,
          cellHeight: 30,
          headers: [
            ['Member', 'Balance']
          ],
          data: balances.entries.map((entry) {
            final balance = entry.value;
            final isNegative = balance < 0;
            return [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  userNames[entry.key] ?? 'Unknown',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(
                  color: isNegative
                      ? const PdfColor.fromInt(0xFFFFF5F5)
                      : const PdfColor.fromInt(0xFFEBF8FF),
                ),
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    '${_settingsService.currency}${balance.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      color: isNegative
                          ? const PdfColor.fromInt(0xFFF56565)
                          : const PdfColor.fromInt(0xFF48BB78),
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ];
          }).toList(),
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(
              color: PdfColor.fromInt(0xFFE2E8F0),
              width: 0.5,
            ),
          ),
          headerStyle: pw.TextStyle(
            color: const PdfColor.fromInt(0xFFFFFFFF),
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
          ),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  pw.Widget _buildSettlements(Map<String, double> balances,
      Map<String, String> userNames, pw.Font ttf) {
    final settlements = _calculateSettlements(balances);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Settlement Plan',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF2D3748),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF4299E1),
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          headerHeight: 25,
          cellHeight: 30,
          headers: ['From', 'To', 'Amount'],
          data: settlements
              .map((s) => [
                    userNames[s['from']] ?? 'Unknown',
                    userNames[s['to']] ?? 'Unknown',
                    '${_settingsService.currency}${s['amount']?.toStringAsFixed(2)}',
                  ])
              .toList(),
          border: null,
          headerStyle: pw.TextStyle(
            color: const PdfColor.fromInt(0xFFFFFFFF),
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
          ),
          cellStyle: pw.TextStyle(
            color: const PdfColor.fromInt(0xFF48BB78),
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
          },
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _calculateSettlements(
      Map<String, double> balances) {
    var debtors = Map.fromEntries(balances.entries.where((e) => e.value < 0));
    var creditors = Map.fromEntries(balances.entries.where((e) => e.value > 0));
    List<Map<String, dynamic>> settlements = [];

    debtors.forEach((debtorId, debtAmount) {
      var debt = debtAmount.abs();
      creditors.forEach((creditorId, creditAmount) {
        if (debt > 0 && creditAmount > 0) {
          var payment = debt < creditAmount ? debt : creditAmount;
          settlements.add({
            'from': debtorId,
            'to': creditorId,
            'amount': payment,
          });
          debt -= payment;
          creditors[creditorId] = creditAmount - payment;
        }
      });
    });

    return settlements;
  }
}

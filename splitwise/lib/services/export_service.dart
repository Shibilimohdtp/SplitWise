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
import 'package:splitwise/constants/app_color.dart';

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
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context pdfContext) => [
          _buildTitle(group, ttf),
          pw.SizedBox(height: 25),
          _buildSummarySection(
              totalExpenses, balances, userNames, currentUserId, ttf),
          pw.SizedBox(height: 25),
          _buildTransactionList(expenses, userNames, ttf),
          pw.SizedBox(height: 25),
          _buildExpenseSplits(expenses, expenseSplits, userNames, ttf),
          pw.SizedBox(height: 25),
          _buildBalances(balances, userNames, ttf),
          pw.SizedBox(height: 25),
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
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(AppColors.primaryDark.toARGB32()),
          ),
        ),
        pw.Text(
          'Group: ${group.name}',
          style: pw.TextStyle(
            fontSize: 18,
            color: PdfColor.fromInt(AppColors.textMain.toARGB32()),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated: ${DateFormat('MMMM d, y').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColor.fromInt(AppColors.textLight.toARGB32()),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColor.fromInt(AppColors.borderLight.toARGB32())),
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
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(AppColors.backgroundLight.toARGB32()),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Financial Overview',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(AppColors.primaryDark.toARGB32()),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard(
                'Total Spent',
                '${_settingsService.currency}${totalExpenses.toStringAsFixed(2)}',
                PdfColor.fromInt(AppColors.primaryMain.toARGB32()),
                ttf,
              ),
              _buildSummaryCard(
                'You Owe',
                '${_settingsService.currency}${youOwe.toStringAsFixed(2)}',
                PdfColor.fromInt(AppColors.negativeBalance.toARGB32()),
                ttf,
              ),
              _buildSummaryCard(
                'You Are Owed',
                '${_settingsService.currency}${youAreOwed.toStringAsFixed(2)}',
                PdfColor.fromInt(AppColors.positiveBalance.toARGB32()),
                ttf,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard(
      String title, String value, PdfColor color, pw.Font ttf) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: ttf,
            fontSize: 12,
            color: PdfColor.fromInt(AppColors.textLight.toARGB32()),
          ),
        ),
        pw.SizedBox(height: 6),
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
    );
  }

  pw.Widget _buildTransactionList(
      List<Expense> expenses, Map<String, String> userNames, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'All Transactions',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(AppColors.primaryDark.toARGB32()),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headerDecoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColor.fromInt(AppColors.borderMain.toARGB32()),
                width: 1.5,
              ),
            ),
          ),
          headerHeight: 25,
          cellHeight: 30,
          headers: ['Date', 'Description', 'Paid By', 'Amount'],
          data: expenses
              .map((e) => [
                    DateFormat('MM/dd/yy').format(e.date),
                    e.description,
                    userNames[e.payerId] ?? 'N/A',
                    '${_settingsService.currency}${e.amount.toStringAsFixed(2)}',
                  ])
              .toList(),
          border: null,
          headerStyle: pw.TextStyle(
            color: PdfColor.fromInt(AppColors.textMain.toARGB32()),
            fontWeight: pw.FontWeight.bold,
            fontSize: 11,
          ),
          cellStyle: pw.TextStyle(
            color: PdfColor.fromInt(AppColors.textLight.toARGB32()),
            fontSize: 10,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
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
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(AppColors.primaryDark.toARGB32()),
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
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(AppColors.surfaceMedium.toARGB32()),
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
                        fontSize: 13,
                        color: PdfColor.fromInt(AppColors.textMain.toARGB32()),
                      ),
                    ),
                    pw.Text(
                      DateFormat('MMM d').format(expense.date),
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 11,
                        color: PdfColor.fromInt(AppColors.textLight.toARGB32()),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColor.fromInt(AppColors.textMain.toARGB32()),
                ),
                cellStyle: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(AppColors.textLight.toARGB32()),
                ),
                headers: ['Member', 'Share', 'Paid', 'Owes'],
                data: splits.entries.map((entry) {
                  final userId = entry.key;
                  final split = entry.value;
                  return [
                    userNames[userId] ?? 'N/A',
                    '${_settingsService.currency}${split['share']?.toStringAsFixed(2) ?? '0.00'}',
                    '${_settingsService.currency}${split['paid']?.toStringAsFixed(2) ?? '0.00'}',
                    '${_settingsService.currency}${split['owes']?.toStringAsFixed(2) ?? '0.00'}',
                  ];
                }).toList(),
                border: null,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 16),
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
          'Final Balances',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(AppColors.primaryDark.toARGB32()),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(
              color: PdfColor.fromInt(AppColors.borderLight.toARGB32()),
              width: 0.5,
            ),
          ),
          children: balances.entries.map((entry) {
            final balance = entry.value;
            final isNegative = balance < 0;
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text(
                    userNames[entry.key] ?? 'N/A',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(AppColors.textMain.toARGB32()),
                    ),
                  ),
                ),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    '${_settingsService.currency}${balance.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      color: isNegative
                          ? PdfColor.fromInt(
                              AppColors.negativeBalance.toARGB32())
                          : PdfColor.fromInt(
                              AppColors.positiveBalance.toARGB32()),
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
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
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(AppColors.primaryDark.toARGB32()),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Column(
          children: settlements.map((s) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColor.fromInt(AppColors.borderLight.toARGB32())),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        userNames[s['from']] ?? 'N/A',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('  owes  '),
                      pw.Text(
                        userNames[s['to']] ?? 'N/A',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Text(
                    '${_settingsService.currency}${s['amount']?.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color:
                          PdfColor.fromInt(AppColors.secondaryMain.toARGB32()),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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

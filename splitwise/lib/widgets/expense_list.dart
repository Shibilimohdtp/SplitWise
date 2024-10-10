import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ExpenseList extends StatefulWidget {
  final String groupId;
  final Function(String) onDeleteExpense;

  ExpenseList({required this.groupId, required this.onDeleteExpense});

  @override
  _ExpenseListState createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  String? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final expenseService = Provider.of<ExpenseService>(context);
    final settingsService = Provider.of<SettingsService>(context);
    final userService = Provider.of<UserService>(context);

    return Column(
      children: [
        _buildFilterBar(context),
        Expanded(
          child: StreamBuilder<List<Expense>>(
            stream: expenseService.getGroupExpenses(
              widget.groupId,
              category: _selectedCategory,
              startDate: _selectedDateRange?.start,
              endDate: _selectedDateRange?.end,
              memberId: _selectedMemberId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No expenses yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final expense = snapshot.data![index];
                  return FutureBuilder<String>(
                    future: userService.getUserName(expense.payerId),
                    builder: (context, creatorSnapshot) {
                      if (creatorSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return SizedBox.shrink();
                      }
                      final creatorName = creatorSnapshot.data ?? 'Unknown';
                      return _buildExpenseCard(
                          context, expense, creatorName, settingsService);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                hint: Text('Category'),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                items: [
                  'All',
                  'Food',
                  'Transport',
                  'Entertainment',
                  'Utilities',
                  'Rent',
                  'Other'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value == 'All' ? null : value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => _selectMember(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense,
      String creatorName, SettingsService settingsService) {
    final theme = Theme.of(context);
    final categoryIcon = _getCategoryIcon(expense.category);

    return Slidable(
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              widget.onDeleteExpense(expense.id);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showExpenseDetails(
              context,
              expense,
              creatorName,
              Provider.of<UserService>(context, listen: false),
              settingsService),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: theme.primaryColor),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: theme.textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Paid by $creatorName',
                        style: theme.textTheme.bodySmall,
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(expense.date),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${settingsService.currency}${expense.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.power;
      case 'rent':
        return Icons.home;
      default:
        return Icons.attach_money;
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 30)),
            end: DateTime.now(),
          ),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _showDateRangeSnackBar(picked);
    }
  }

  void _showDateRangeSnackBar(DateTimeRange range) {
    final startFormatted = DateFormat('MMM d, y').format(range.start);
    final endFormatted = DateFormat('MMM d, y').format(range.end);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Date range: $startFormatted - $endFormatted'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Clear',
          onPressed: () {
            setState(() {
              _selectedDateRange = null;
            });
          },
        ),
      ),
    );
  }

  Future<void> _selectMember(BuildContext context) async {
    final userService = Provider.of<UserService>(context, listen: false);
    final members = await userService.getGroupMembers([widget.groupId]);
    final selectedMember = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select Member'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: Text('All Members'),
            ),
            ...members
                .map((member) => SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context, member.uid);
                      },
                      child: Text(member.name),
                    ))
                .toList(),
          ],
        );
      },
    );

    setState(() {
      _selectedMemberId = selectedMember;
    });

    if (selectedMember != null) {
      final memberName = await userService.getUserName(selectedMember);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filtered by member: $memberName'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Clear',
            onPressed: () {
              setState(() {
                _selectedMemberId = null;
              });
            },
          ),
        ),
      );
    }
  }

  void _showExpenseDetails(
      BuildContext context,
      Expense expense,
      String creatorName,
      UserService userService,
      SettingsService settingsService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.description,
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    Text(
                        'Amount: ${settingsService.currency}${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Paid by: $creatorName'),
                    Text('Date: ${expense.date.toString().split(' ')[0]}'),
                    Text('Category: ${expense.category}'),
                    if (expense.comment != null && expense.comment!.isNotEmpty)
                      Text('Comment: ${expense.comment}'),
                    SizedBox(height: 16),
                    Text('Split Details:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    FutureBuilder<List<Widget>>(
                      future: _buildSplitDetailsList(
                          expense, userService, settingsService),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading split details');
                        }
                        return Column(children: snapshot.data!);
                      },
                    ),
                    if (expense.receiptUrl != null) ...[
                      SizedBox(height: 16),
                      ElevatedButton(
                        child: Text('View Receipt'),
                        onPressed: () {
                          // Implement receipt viewing logic here
                          // You might want to open a new screen or show a dialog with the image
                        },
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          child: Text('Close'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        ElevatedButton(
                          child: Text('Delete'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () {
                            widget.onDeleteExpense(expense.id);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Widget>> _buildSplitDetailsList(Expense expense,
      UserService userService, SettingsService settingsService) async {
    List<Widget> splitDetailWidgets = [];
    for (var entry in expense.splitDetails.entries) {
      String userName = await userService.getUserName(entry.key);
      splitDetailWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(userName),
              Text(
                  '${settingsService.currency}${entry.value.toStringAsFixed(2)}'),
            ],
          ),
        ),
      );
    }
    return splitDetailWidgets;
  }
}

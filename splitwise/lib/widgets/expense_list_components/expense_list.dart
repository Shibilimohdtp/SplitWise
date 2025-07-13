import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/widgets/expense_list_components/expense_card.dart';
import 'package:splitwise/widgets/expense_list_components/expense_filter_section.dart';
import 'package:splitwise/widgets/expense_list_components/expense_details_bottom_sheet.dart';
import 'package:splitwise/widgets/expense_list_components/expense_filter_dialogs.dart';

class ExpenseList extends StatefulWidget {
  final String groupId;
  final Function(String) onDeleteExpense;
  final List<dynamic> members;

  const ExpenseList({
    super.key,
    required this.groupId,
    required this.onDeleteExpense,
    required this.members,
  });

  @override
  ExpenseListState createState() => ExpenseListState();
}

class ExpenseListState extends State<ExpenseList> {
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
        ExpenseFilterSection(
          selectedCategory: _selectedCategory,
          selectedDateRange: _selectedDateRange,
          selectedMemberId: _selectedMemberId,
          onCategoryChanged: (value) =>
              setState(() => _selectedCategory = value),
          onSelectDateRange: () => _selectDateRange(context),
          onSelectMember: () => _selectMember(context),
          onClearFilters: () => setState(() {
            _selectedCategory = null;
            _selectedDateRange = null;
            _selectedMemberId = null;
          }),
        ),
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
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }
              return _buildExpenseListView(
                  snapshot.data!, userService, settingsService);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final result = await ExpenseFilterDialogs.showDateRangeFilterDialog(
        context, _selectedDateRange);
    setState(() => _selectedDateRange = result);
  }

  Future<void> _selectMember(BuildContext context) async {
    final selectedMember = await ExpenseFilterDialogs.showMemberSelectionDialog(
        context, widget.members);
    setState(() => _selectedMemberId = selectedMember);
  }

  Widget _buildExpenseListView(
    List<Expense> expenses,
    UserService userService,
    SettingsService settingsService,
  ) {
    Map<String, List<Expense>> groupedExpenses = {};
    for (var expense in expenses) {
      String date = DateFormat('MMMM d, yyyy').format(expense.date);
      if (groupedExpenses[date] == null) {
        groupedExpenses[date] = [];
      }
      groupedExpenses[date]!.add(expense);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        String date = groupedExpenses.keys.elementAt(index);
        List<Expense> dailyExpenses = groupedExpenses[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date),
            ...dailyExpenses.map((expense) => FutureBuilder<String>(
                  future: _getPayerName(userService, expense.payerId),
                  builder: (context, creatorSnapshot) {
                    final creatorName = creatorSnapshot.data ?? '...';
                    return ExpenseCard(
                      expense: expense,
                      creatorName: creatorName,
                      settingsService: settingsService,
                      onTap: (expense) => _showExpenseDetails(
                          expense, creatorName, settingsService, userService),
                      onDelete: (expense) => widget.onDeleteExpense(expense.id),
                    );
                  },
                )),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        date,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or add a new expense.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'An error occurred',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<String> _getPayerName(UserService userService, String payerId) async {
    final isUser = await userService.isUser(payerId);
    if (isUser) {
      return userService.getUserName(payerId);
    }
    return payerId;
  }

  void _showExpenseDetails(
    Expense expense,
    String creatorName,
    SettingsService settingsService,
    UserService userService,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseDetailsBottomSheet(
        expense: expense,
        creatorName: creatorName,
        settingsService: settingsService,
        userService: userService,
        onDeleteExpense: widget.onDeleteExpense,
      ),
    );
  }
}

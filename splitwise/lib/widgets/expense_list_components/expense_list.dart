import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  const ExpenseList(
      {super.key, required this.groupId, required this.onDeleteExpense});

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
          onCategoryChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
            if (value != null) {
              _showFilterSnackBar('Filtered by category: $value');
            }
          },
          onSelectDateRange: () => _selectDateRange(context),
          onSelectMember: () => _selectMember(context),
          onClearFilters: () {
            setState(() {
              _selectedCategory = null;
              _selectedDateRange = null;
              _selectedMemberId = null;
            });
            _showFilterSnackBar('All filters cleared');
          },
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
                return _buildLoadingState();
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

    if (result == null) {
      setState(() {
        _selectedDateRange = null;
      });
      _showFilterSnackBar('Showing all expenses');
    } else {
      setState(() {
        _selectedDateRange = result;
      });
      final dateText = ExpenseFilterDialogs.getDateRangeDisplayText(result);
      _showFilterSnackBar('Showing expenses for: $dateText');
    }
  }

  Future<void> _selectMember(BuildContext context) async {
    if (!mounted) return;

    final userService = Provider.of<UserService>(context, listen: false);

    try {
      // First, get the group to access its members list
      final groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (!groupSnapshot.exists) {
        if (!mounted) return;
        _showErrorSnackBar('Group not found');
        return;
      }

      final groupData = groupSnapshot.data()!;
      final List<String> memberIds =
          List<String>.from(groupData['members'] ?? []);

      // Now get the actual user objects for these member IDs
      final members = await userService.getGroupMembers(memberIds);

      if (!mounted) return;

      final selectedMember =
          await ExpenseFilterDialogs.showMemberSelectionDialog(
              // ignore: use_build_context_synchronously
              context,
              members);

      if (!mounted) return;

      setState(() {
        _selectedMemberId = selectedMember;
      });

      if (selectedMember != null) {
        final memberName = await userService.getUserName(selectedMember);

        if (!mounted) return;

        _showFilterSnackBar('Filtered by member: $memberName');
      } else {
        _showFilterSnackBar('Showing expenses for all members');
      }
    } catch (e) {
      if (!mounted) return;

      _showErrorSnackBar('Failed to load members: ${e.toString()}');
    }
  }

  void _showFilterSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        action: _selectedCategory != null ||
                _selectedDateRange != null ||
                _selectedMemberId != null
            ? SnackBarAction(
                label: 'Clear',
                textColor: Theme.of(context).colorScheme.onTertiary,
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedDateRange = null;
                    _selectedMemberId = null;
                  });
                },
              )
            : null,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildExpenseListView(
    List<Expense> expenses,
    UserService userService,
    SettingsService settingsService,
  ) {
    String? currentDate;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final expenseDate = DateFormat('MMMM d, y').format(expense.date);
        final showDateHeader = currentDate != expenseDate;

        if (showDateHeader) {
          currentDate = expenseDate;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader) _buildDateHeader(expenseDate),
            FutureBuilder<String>(
              future: _getPayerName(userService, expense.payerId),
              builder: (context, creatorSnapshot) {
                if (creatorSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _buildExpenseCardSkeleton();
                }
                final creatorName = creatorSnapshot.data ?? 'Unknown';
                return ExpenseCard(
                  expense: expense,
                  creatorName: creatorName,
                  settingsService: settingsService,
                  onTap: (expense) => _showExpenseDetails(
                      expense, creatorName, settingsService, userService),
                  onDelete: (expense) => widget.onDeleteExpense(expense.id),
                );
              },
            ),
            SizedBox(height: index == expenses.length - 1 ? 24 : 4),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 12,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            date,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: _buildExpenseCardSkeleton(),
      ),
    );
  }

  Widget _buildExpenseCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.1),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Expenses Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add your first expense to start tracking group expenses',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  KeepAliveWrapperState createState() => KeepAliveWrapperState();
}

class KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

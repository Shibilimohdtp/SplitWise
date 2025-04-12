import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/services/settings_service.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:splitwise/utils/app_color.dart';

class ExpenseList extends StatefulWidget {
  final String groupId;
  final Function(String) onDeleteExpense;

  const ExpenseList(
      {super.key, required this.groupId, required this.onDeleteExpense});

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
        _buildFilterSection(),
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

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCategoryDropdown(),
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                icon: Icons.date_range_outlined,
                label: _selectedDateRange != null ? 'Date ✓' : 'Date',
                onTap: () => _selectDateRange(context),
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                icon: Icons.person_outline,
                label: _selectedMemberId != null ? 'Member ✓' : 'Member',
                onTap: () => _selectMember(context),
              ),
            ],
          ),
        ],
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
          title: const Text('Select Member'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('All Members'),
            ),
            ...members.map((member) => SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, member.uid);
                  },
                  child: Text(member.name),
                )),
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
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.accentMain,
          action: SnackBarAction(
            label: 'Clear',
            textColor: AppColors.backgroundLight,
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

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: const Text('Category',
              style: TextStyle(color: AppColors.textLight)),
          isExpanded: true,
          icon:
              const Icon(Icons.keyboard_arrow_down, color: AppColors.textMain),
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Categories'),
            ),
            ..._buildCategoryItems(),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildCategoryItems() {
    final categories = [
      'Food',
      'Transport',
      'Entertainment',
      'Utilities',
      'Rent',
      'Other'
    ];

    return categories.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Icon(_getCategoryIcon(value), size: 18, color: AppColors.textMain),
            const SizedBox(width: 8),
            Text(value),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMain),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
              future: userService.getUserName(expense.payerId),
              builder: (context, creatorSnapshot) {
                if (creatorSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _buildExpenseCardSkeleton();
                }
                final creatorName = creatorSnapshot.data ?? 'Unknown';
                return _buildExpenseCard(expense, creatorName, settingsService);
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
      padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
      child: Text(
        date,
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExpenseCard(
    Expense expense,
    String creatorName,
    SettingsService settingsService,
  ) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      onDismissed: (direction) {
        widget.onDeleteExpense(expense.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: InkWell(
          onTap: () =>
              _showExpenseDetails(expense, creatorName, settingsService),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCategoryIcon(expense.category),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paid by $creatorName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${settingsService.currency}${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(expense.category),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        expense.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getCategoryIcon(category),
        color: _getCategoryColor(category),
        size: 24,
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Time Period',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildQuickSelectChip(
                    label: 'Last 7 days',
                    onTap: () => _setQuickDateRange(7),
                  ),
                  _buildQuickSelectChip(
                    label: 'Last 30 days',
                    onTap: () => _setQuickDateRange(30),
                  ),
                  _buildQuickSelectChip(
                    label: 'Last 3 months',
                    onTap: () => _setQuickDateRange(90),
                  ),
                  _buildQuickSelectChip(
                    label: 'Last 6 months',
                    onTap: () => _setQuickDateRange(180),
                  ),
                  _buildQuickSelectChip(
                    label: 'This year',
                    onTap: () {
                      final now = DateTime.now();
                      final startOfYear = DateTime(now.year, 1, 1);
                      _setCustomDateRange(startOfYear, now);
                    },
                  ),
                  _buildQuickSelectChip(
                    label: 'All time',
                    onTap: () {
                      setState(() => _selectedDateRange = null);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Showing all expenses'),
                          backgroundColor: AppColors.accentMain,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final ThemeData theme = Theme.of(context);
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDateRange: _selectedDateRange ??
                        DateTimeRange(
                          start:
                              DateTime.now().subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        ),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: theme.copyWith(
                          colorScheme: theme.colorScheme.copyWith(
                            primary: AppColors.primaryMain,
                            onPrimary: Colors.white,
                            surface: AppColors.surfaceLight,
                            onSurface: AppColors.textMain,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    _setCustomDateRange(picked.start, picked.end);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: AppColors.primaryMain),
                      SizedBox(width: 12),
                      Text(
                        'Custom Range',
                        style: TextStyle(
                          color: AppColors.primaryMain,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppColors.textLight),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _setQuickDateRange(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    _setCustomDateRange(start, now);
  }

  void _setCustomDateRange(DateTime start, DateTime end) {
    setState(() {
      _selectedDateRange = DateTimeRange(start: start, end: end);
    });
    _showDateRangeSnackBar(_selectedDateRange!);
  }

  void _showDateRangeSnackBar(DateTimeRange range) {
    String dateText;
    final now = DateTime.now();
    final start = range.start;
    final end = range.end;

    final difference = end.difference(start).inDays;

    if (difference == 6) {
      dateText = 'Last 7 days';
    } else if (difference == 29) {
      dateText = 'Last 30 days';
    } else if (difference == 89) {
      dateText = 'Last 3 months';
    } else if (difference == 179) {
      dateText = 'Last 6 months';
    } else if (start.year == end.year &&
        start.month == 1 &&
        start.day == 1 &&
        end.day == now.day &&
        end.month == now.month) {
      dateText = 'This year';
    } else {
      final startFormatted = DateFormat('MMM d').format(start);
      final endFormatted = DateFormat('MMM d').format(end);
      dateText = '$startFormatted - $endFormatted';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing expenses for: $dateText'),
        backgroundColor: AppColors.accentMain,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Clear',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _selectedDateRange = null;
            });
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFF4CAF50);
      case 'transport':
        return const Color(0xFF2196F3);
      case 'entertainment':
        return const Color(0xFF9C27B0);
      case 'utilities':
        return const Color(0xFFFF9800);
      case 'rent':
        return const Color(0xFF795548);
      default:
        return const Color(0xFF607D8B);
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildExpenseCardSkeleton(),
    );
  }

  Widget _buildExpenseCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(12),
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
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
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
              color: AppColors.borderLight,
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
              color: AppColors.primaryMain.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.primaryMain,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Expenses Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first expense to start tracking',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
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
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(
    Expense expense,
    String creatorName,
    SettingsService settingsService,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                _buildBottomSheetHandle(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildExpenseHeader(expense, settingsService),
                        const SizedBox(height: 24),
                        _buildExpenseInfo(expense, creatorName),
                        if (expense.comment?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 24),
                          _buildCommentSection(expense.comment!),
                        ],
                        const SizedBox(height: 24),
                        _buildSplitDetails(expense, settingsService),
                        if (expense.receiptUrl != null) ...[
                          const SizedBox(height: 24),
                          _buildReceiptButton(expense.receiptUrl!),
                        ],
                        const SizedBox(height: 32),
                        _buildActionButtons(expense),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomSheetHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.borderMain,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildExpenseHeader(Expense expense, SettingsService settingsService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                expense.description,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _getCategoryColor(expense.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                expense.category,
                style: TextStyle(
                  color: _getCategoryColor(expense.category),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${settingsService.currency}${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryMain,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseInfo(Expense expense, String creatorName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Paid by',
            value: creatorName,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: DateFormat('MMMM d, yyyy').format(expense.date),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: expense.category,
            valueColor: _getCategoryColor(expense.category),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryMain.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryMain, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentSection(String comment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitDetails(Expense expense, SettingsService settingsService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Split Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: FutureBuilder<List<Widget>>(
            future: _buildSplitDetailsList(expense, settingsService),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryMain),
                );
              }
              return Column(children: snapshot.data ?? []);
            },
          ),
        ),
      ],
    );
  }

  Future<List<Widget>> _buildSplitDetailsList(
    Expense expense,
    SettingsService settingsService,
  ) async {
    final userService = Provider.of<UserService>(context, listen: false);
    List<Widget> widgets = [];

    for (var entry in expense.splitDetails.entries) {
      final userName = await userService.getUserName(entry.key);
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                ),
              ),
              Text(
                '${settingsService.currency}${entry.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildReceiptButton(String receiptUrl) {
    return ElevatedButton.icon(
      onPressed: () => _viewReceipt(context, receiptUrl),
      icon: const Icon(Icons.receipt_outlined),
      label: const Text('View Receipt'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryMain,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Expense expense) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMain,
              side: const BorderSide(color: AppColors.borderMain),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteExpense(expense.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ),
      ],
    );
  }

  Future<void> _viewReceipt(BuildContext context, String receiptUrl) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Receipt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: Image.network(
                  receiptUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Failed to load receipt image',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

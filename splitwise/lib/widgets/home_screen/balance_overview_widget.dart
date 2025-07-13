import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/utils/currency_utils.dart';
import 'package:splitwise/widgets/home_screen/monthly_summary_bottom_sheet.dart';

// Balance Overview Widget for the home screen

class BalanceOverviewWidget extends StatefulWidget {
  final String userId;

  const BalanceOverviewWidget({
    super.key,
    required this.userId,
  });

  @override
  BalanceOverviewWidgetState createState() => BalanceOverviewWidgetState();
}

class BalanceOverviewWidgetState extends State<BalanceOverviewWidget> {
  late PageController _balancePageController;
  late ValueNotifier<double> _pagePositionNotifier;

  // Use Futures to manage async data loading and caching implicitly
  Future<Map<String, double>>? _balanceFuture;
  Future<List<Map<String, dynamic>>>? _recentActivityFuture;
  Future<Map<String, dynamic>>? _monthlySummaryFuture;

  late ExpenseService _expenseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();

    // Balance card page controller
    _balancePageController = PageController(initialPage: 0);
    _pagePositionNotifier = ValueNotifier<double>(0.0);
    _balancePageController.addListener(() {
      _pagePositionNotifier.value = _balancePageController.page ?? 0;
    });

    // Note: Futures are initialized in didChangeDependencies
    // because they depend on _expenseService
  }

  @override
  void didUpdateWidget(BalanceOverviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      // If the userId changes, re-fetch the data
      _fetchData();
    }
  }

  void _fetchData() {
    _balanceFuture = _expenseService.calculateOverallBalance(widget.userId);
    _recentActivityFuture = _fetchRecentActivity();
    _monthlySummaryFuture = _fetchMonthlySummary();
    if (mounted) {
      setState(() {}); // Trigger a rebuild
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    _expenseService = ExpenseService(settingsService);
    _fetchData();
    // Initialize futures only once
    _balanceFuture ??= _expenseService.calculateOverallBalance(widget.userId);
    _recentActivityFuture ??=
        _fetchRecentActivity(); // Use helper for demo data
    _monthlySummaryFuture ??=
        _fetchMonthlySummary(); // Use helper for demo data
  }

  // Fetch recent activity data from all user groups
  Future<List<Map<String, dynamic>>> _fetchRecentActivity() async {
    try {
      // Get all groups the user is a member of
      final userGroupsById = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: widget.userId)
          .get();

      final userGroupsByEmail = await _firestore
          .collection('groups')
          .where('invitedEmails', arrayContains: widget.userId)
          .get();

      final userGroups = [...userGroupsById.docs, ...userGroupsByEmail.docs];

      // Collect recent expenses from all groups
      List<Map<String, dynamic>> recentActivity = [];

      for (var groupDoc in userGroups) {
        final groupId = groupDoc.id;
        final groupName = groupDoc.data()['name'] ?? 'Unknown Group';

        // Get recent expenses for this group (limit to 5 per group)
        final expenses = await _firestore
            .collection('expenses')
            .where('groupId', isEqualTo: groupId)
            .orderBy('date', descending: true)
            .limit(5)
            .get();

        // Add each expense to the activity list with group info
        for (var doc in expenses.docs) {
          final expense = Expense.fromFirestore(doc);
          // Use the class instance instead of creating a new one
          final isPayerUser = await _userService.isUser(expense.payerId);
          final payerName = isPayerUser
              ? await _userService.getUserName(expense.payerId)
              : expense.payerId;

          // Calculate if this is a positive or negative transaction for the current user
          double userAmount = 0;
          if (expense.payerId == widget.userId) {
            // User paid, so it's positive (others owe user)
            userAmount =
                expense.amount - (expense.splitDetails[widget.userId] ?? 0);
          } else {
            // User didn't pay, so it's negative (user owes payer)
            userAmount = -(expense.splitDetails[widget.userId] ?? 0);
          }

          recentActivity.add({
            'expense': expense,
            'groupName': groupName,
            'payerName': payerName,
            'userAmount': userAmount,
          });
        }
      }

      // Sort all activities by date (most recent first)
      recentActivity.sort((a, b) {
        final aExpense = a['expense'] as Expense;
        final bExpense = b['expense'] as Expense;
        return bExpense.date.compareTo(aExpense.date);
      });

      // Limit to most recent 10 activities
      if (recentActivity.length > 10) {
        recentActivity = recentActivity.sublist(0, 10);
      }

      return recentActivity;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recent activity: $e');
      }
      return [];
    }
  }

  // Fetch monthly summary data from all user groups
  Future<Map<String, dynamic>> _fetchMonthlySummary() async {
    try {
      // Get all groups the user is a member of
      final userGroupsById = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: widget.userId)
          .get();

      final userGroupsByEmail = await _firestore
          .collection('groups')
          .where('invitedEmails', arrayContains: widget.userId)
          .get();

      final userGroups = [...userGroupsById.docs, ...userGroupsByEmail.docs];

      // Get current and previous month dates
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final twoMonthsAgoStart = DateTime(now.year, now.month - 2, 1);

      double thisMonthTotal = 0;
      double lastMonthTotal = 0;
      double twoMonthsAgoTotal = 0;

      // For each group, get expenses and calculate monthly totals
      for (var groupDoc in userGroups) {
        final groupId = groupDoc.id;

        // Get expenses for the last 3 months
        final expenses = await _firestore
            .collection('expenses')
            .where('groupId', isEqualTo: groupId)
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(twoMonthsAgoStart))
            .orderBy('date', descending: true)
            .get();

        // Calculate user's share for each expense
        for (var doc in expenses.docs) {
          final expense = Expense.fromFirestore(doc);
          final expenseDate = expense.date;

          // Calculate user's share in this expense
          double userShare = 0;
          if (expense.payerId == widget.userId) {
            // User paid, so it's the amount minus their own share
            userShare =
                expense.amount - (expense.splitDetails[widget.userId] ?? 0);
          } else {
            // User didn't pay, so it's negative what they owe
            userShare = -(expense.splitDetails[widget.userId] ?? 0);
          }

          // Add to appropriate month total
          if (expenseDate.isAfter(thisMonthStart) ||
              (expenseDate.year == thisMonthStart.year &&
                  expenseDate.month == thisMonthStart.month &&
                  expenseDate.day == thisMonthStart.day)) {
            thisMonthTotal += userShare;
          } else if (expenseDate.isAfter(lastMonthStart) ||
              (expenseDate.year == lastMonthStart.year &&
                  expenseDate.month == lastMonthStart.month &&
                  expenseDate.day == lastMonthStart.day)) {
            lastMonthTotal += userShare;
          } else if (expenseDate.isAfter(twoMonthsAgoStart) ||
              (expenseDate.year == twoMonthsAgoStart.year &&
                  expenseDate.month == twoMonthsAgoStart.month &&
                  expenseDate.day == twoMonthsAgoStart.day)) {
            twoMonthsAgoTotal += userShare;
          }
        }
      }

      // Calculate month-to-month change percentage
      double monthlyChangePercent = 0;
      if (lastMonthTotal != 0) {
        monthlyChangePercent =
            ((thisMonthTotal - lastMonthTotal) / lastMonthTotal.abs()) * 100;
      }

      // Format month names
      final monthFormat = DateFormat('MMMM');
      final thisMonthName = monthFormat.format(now);
      final lastMonthName =
          monthFormat.format(DateTime(now.year, now.month - 1));

      return {
        'thisMonthName': thisMonthName,
        'lastMonthName': lastMonthName,
        'thisMonthTotal': thisMonthTotal,
        'lastMonthTotal': lastMonthTotal,
        'twoMonthsAgoTotal': twoMonthsAgoTotal,
        'monthlyChangePercent': monthlyChangePercent,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching monthly summary: $e');
      }
      // Return empty data on error
      return {
        'thisMonthName': DateFormat('MMMM').format(DateTime.now()),
        'lastMonthName': DateFormat('MMMM')
            .format(DateTime(DateTime.now().year, DateTime.now().month - 1)),
        'thisMonthTotal': 0.0,
        'lastMonthTotal': 0.0,
        'twoMonthsAgoTotal': 0.0,
        'monthlyChangePercent': 0.0,
      };
    }
  }

  @override
  void dispose() {
    _balancePageController.dispose();
    _pagePositionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access theme data once
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsService = Provider.of<SettingsService>(context);
    final currencySymbol = getCurrencySymbol(settingsService.currency);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160, // Keep original height
            child: NotificationListener<ScrollNotification>(
              // Prevent scroll events from propagating to parent
              onNotification: (notification) => true,
              child: PageView.builder(
                controller: _balancePageController,
                itemCount: 3,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      // Use FutureBuilder for balance page
                      return FutureBuilder<Map<String, double>>(
                        future: _balanceFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // Show skeleton only while the first page is loading
                            return _buildBalanceOverviewSkeleton(context);
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (snapshot.hasData) {
                            final balance =
                                snapshot.data ?? {'owed': 0, 'owing': 0};
                            return _buildOverallBalancePageContent(
                                context, balance, currencySymbol);
                          } else {
                            return const Center(child: Text('No balance data'));
                          }
                        },
                      );
                    case 1:
                      // Use FutureBuilder for recent activity
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: _recentActivityFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (snapshot.hasData) {
                            return _buildRecentActivityPageContent(
                                context, snapshot.data!, currencySymbol);
                          } else {
                            return const Center(
                                child: Text('No activity data'));
                          }
                        },
                      );
                    case 2:
                      // Use FutureBuilder for monthly summary
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _monthlySummaryFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (snapshot.hasData) {
                            return _buildMonthlySummaryPageContent(
                                context, snapshot.data!, currencySymbol);
                          } else {
                            return const Center(child: Text('No summary data'));
                          }
                        },
                      );
                    default:
                      // Fallback, should not happen with itemCount: 3
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
          // Page indicators remain the same
          _buildPageIndicators(context),
        ],
      ),
    );
  }

  // Extracted content logic for the balance page
  Widget _buildOverallBalancePageContent(BuildContext context,
      Map<String, double> balance, String currencySymbol) {
    final totalOwed = balance['owed'] ?? 0;
    final totalOwing = balance['owing'] ?? 0;
    final netBalance = totalOwed - totalOwing;

    final totalTransactions = totalOwed + totalOwing;
    final owedPercentage =
        totalTransactions > 0 ? totalOwed / totalTransactions : 0.5;

    final isPositive = netBalance >= 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final balanceColor = isPositive ? colorScheme.tertiary : colorScheme.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with balance info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Balance amount and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with icon
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total Balance',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Balance amount
                    Text(
                      '$currencySymbol${netBalance.abs().toStringAsFixed(2)}',
                      style: textTheme.headlineMedium?.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Status indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: balanceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: balanceColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? 'Net positive' : 'Net negative',
                      style: textTheme.labelMedium?.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Balance progress indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Labels for the progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'You are owed',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'You owe',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Progress bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                // Ensure flex values are non-zero and integers
                child: Row(
                  children: [
                    Expanded(
                      flex: (owedPercentage * 100).clamp(0, 100).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - owedPercentage) * 100).clamp(0, 100).toInt(),
                      child:
                          Container(), // Empty container for the remaining space
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Amounts below the progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currencySymbol${totalOwed.toStringAsFixed(2)}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  Text(
                    '$currencySymbol${totalOwing.toStringAsFixed(2)}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Extracted content logic for the recent activity page
  Widget _buildRecentActivityPageContent(BuildContext context,
      List<Map<String, dynamic>> recentActivity, String currencySymbol) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Row(
            children: [
              Icon(
                Icons.history_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Recent Activity',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Activity list
          Expanded(
            child: _buildRecentActivityList(
                context, recentActivity, currencySymbol),
          ),
        ],
      ),
    );
  }

  // Helper to build the list content or empty state for recent activity
  Widget _buildRecentActivityList(BuildContext context,
      List<Map<String, dynamic>> activityData, String currencySymbol) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    if (activityData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: colorScheme.outline.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: activityData.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: colorScheme.outline.withValues(alpha: 0.1),
        indent: 48, // Aligns with the content after the leading icon
      ),
      itemBuilder: (context, index) {
        final activityItem = activityData[index];
        final expense = activityItem['expense'] as Expense;
        final groupName = activityItem['groupName'] as String;
        // Get payer name for display if needed
        final payerName = activityItem['payerName'] as String;
        // Add payer name to description if it's not the current user
        final descriptionText = expense.payerId != widget.userId
            ? '${expense.description} (paid by $payerName)'
            : expense.description;
        final userAmount = activityItem['userAmount'] as double;

        final isPositive = userAmount >= 0;
        final statusColor =
            isPositive ? colorScheme.tertiary : colorScheme.error;
        final now = DateTime.now();
        final expenseDate = expense.date;

        // Format the date relative to today
        String dateText;
        if (expenseDate.year == now.year &&
            expenseDate.month == now.month &&
            expenseDate.day == now.day) {
          dateText = 'Today, ${timeFormat.format(expenseDate)}';
        } else if (expenseDate.year == now.year &&
            expenseDate.month == now.month &&
            expenseDate.day == now.day - 1) {
          dateText = 'Yesterday, ${timeFormat.format(expenseDate)}';
        } else {
          dateText = dateFormat.format(expenseDate);
        }

        // Determine the icon based on the expense category
        IconData categoryIcon;
        switch (expense.category.toLowerCase()) {
          case 'food':
          case 'groceries':
          case 'dining':
          case 'restaurant':
            categoryIcon = Icons.restaurant_outlined;
            break;
          case 'transportation':
          case 'travel':
            categoryIcon = Icons.directions_car_outlined;
            break;
          case 'entertainment':
          case 'movie':
            categoryIcon = Icons.movie_outlined;
            break;
          case 'shopping':
            categoryIcon = Icons.shopping_bag_outlined;
            break;
          case 'utilities':
          case 'bills':
            categoryIcon = Icons.receipt_outlined;
            break;
          case 'settlement':
            categoryIcon = Icons.account_balance_wallet_outlined;
            break;
          default:
            categoryIcon = Icons.receipt_outlined;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Activity icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              // Activity details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descriptionText,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          dateText,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            groupName,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositive ? '+' : '-'}$currencySymbol${userAmount.abs().toStringAsFixed(2)}',
                  style: textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Extracted content logic for the monthly summary page
  Widget _buildMonthlySummaryPageContent(BuildContext context,
      Map<String, dynamic> summaryData, String currencySymbol) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Extract data from the summary
    final thisMonthName = summaryData['thisMonthName'] as String;
    final lastMonthName = summaryData['lastMonthName'] as String;
    final thisMonthTotal = summaryData['thisMonthTotal'] as double;
    final lastMonthTotal = summaryData['lastMonthTotal'] as double;
    final monthlyChangePercent = summaryData['monthlyChangePercent'] as double;

    // Determine if the change is positive or negative
    final isPositiveChange = monthlyChangePercent >= 0;
    final changeColor =
        isPositiveChange ? colorScheme.tertiary : colorScheme.error;
    final changeIcon = isPositiveChange
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Monthly Summary',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Monthly summary content
          Expanded(
            child: Column(
              children: [
                // Monthly comparison cards
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // This month card
                      Expanded(
                        child: _buildCompactMonthlySummaryCard(
                          context,
                          thisMonthName,
                          '$currencySymbol${thisMonthTotal.abs().toStringAsFixed(2)}',
                          Icons.calendar_today_outlined,
                          thisMonthTotal >= 0
                              ? colorScheme.tertiary
                              : colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Last month card
                      Expanded(
                        child: _buildCompactMonthlySummaryCard(
                          context,
                          lastMonthName,
                          '$currencySymbol${lastMonthTotal.abs().toStringAsFixed(2)}',
                          Icons.calendar_month_outlined,
                          lastMonthTotal >= 0
                              ? colorScheme.tertiary
                              : colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Combined action row
                Row(
                  children: [
                    // Trend indicator with actual data
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: changeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              changeIcon,
                              size: 14,
                              color: changeColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${isPositiveChange ? '+' : ''}${monthlyChangePercent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: changeColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action button with navigation
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          // Show monthly summary bottom sheet instead of navigating
                          MonthlySummaryBottomSheet.show(
                              context, summaryData, widget.userId);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.insights_outlined,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'View Analysis',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for monthly summary card (remains mostly the same)
  Widget _buildCompactMonthlySummaryCard(BuildContext context, String label,
      String amount, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label and icon
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Amount
          Text(
            amount,
            style: textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Page indicators logic remains the same
  Widget _buildPageIndicators(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<double>(
      valueListenable: _pagePositionNotifier,
      builder: (context, pagePosition, _) {
        final currentPage = pagePosition.round();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: currentPage == index ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              // Swipe hint text
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe_rounded,
                      size: 12,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Swipe for insights',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Skeleton structure remains mostly the same, shown only for the first page load
  Widget _buildBalanceOverviewSkeleton(BuildContext context) {
    // Only building the content part of the skeleton, as it's placed inside the PageView item
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title and balance skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with icon
                    Row(
                      children: [
                        _buildSkeletonBox(context, size: 16),
                        const SizedBox(width: 6),
                        _buildSkeletonLine(context, width: 80, height: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Balance amount
                    _buildSkeletonLine(context, width: 120, height: 28),
                  ],
                ),
              ),
              // Status indicator skeleton
              _buildSkeletonLine(context, width: 80, height: 28, radius: 14),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar section skeleton
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSkeletonLine(context, width: 60, height: 10),
                  _buildSkeletonLine(context, width: 60, height: 10),
                ],
              ),
              const SizedBox(height: 4),
              // Progress bar
              _buildSkeletonLine(context,
                  width: double.infinity, height: 6, radius: 3),
              const SizedBox(height: 8), // Adjusted spacing to match content
              // Amounts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSkeletonLine(context, width: 50, height: 12),
                  _buildSkeletonLine(context, width: 50, height: 12),
                ],
              ),
            ],
          ),
          // No Spacer or action buttons needed here as it's just the content skeleton
        ],
      ),
    );
  }

  // Skeleton helpers (now require BuildContext to access theme)
  Widget _buildSkeletonLine(BuildContext context,
      {required double width, required double height, double? radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius ?? height / 2),
      ),
    );
  }

  Widget _buildSkeletonBox(BuildContext context, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size / 4),
      ),
    );
  }
}

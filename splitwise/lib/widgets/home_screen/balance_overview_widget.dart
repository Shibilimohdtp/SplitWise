import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';

// Extension for Color manipulation (keeps the original behavior)
extension ColorAlpha on Color {
  Color withValues({double? alpha}) {
    return withAlpha((alpha != null ? (alpha * 255).round() : (a * 255).round())
        .clamp(0, 255));
  }
}

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
  Future<List<dynamic>>? _recentActivityFuture;
  Future<Map<String, String>>? _monthlySummaryFuture;

  late ExpenseService _expenseService;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    _expenseService = ExpenseService(settingsService);

    // Initialize futures only once
    _balanceFuture ??= _expenseService.calculateOverallBalance(widget.userId);
    _recentActivityFuture ??=
        _fetchRecentActivity(); // Use helper for demo data
    _monthlySummaryFuture ??=
        _fetchMonthlySummary(); // Use helper for demo data
  }

  // Helper function for demo recent activity data
  Future<List<dynamic>> _fetchRecentActivity() async {
    // Simulate network delay as in the original code
    await Future.delayed(const Duration(milliseconds: 500));
    // Return empty list as per original placeholder logic
    return [];
  }

  // Helper function for demo monthly summary data
  Future<Map<String, String>> _fetchMonthlySummary() async {
    // Simulate network delay as in the original code
    await Future.delayed(const Duration(milliseconds: 300));
    // Return placeholder data as per original logic
    return {
      'thisMonth': '\$245.75',
      'lastMonth': '\$198.30',
    };
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

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      shadowColor: theme.shadowColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
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
                                context, balance);
                          } else {
                            return const Center(child: Text('No balance data'));
                          }
                        },
                      );
                    case 1:
                      // Use FutureBuilder for recent activity
                      return FutureBuilder<List<dynamic>>(
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
                                context, snapshot.data!);
                          } else {
                            return const Center(
                                child: Text('No activity data'));
                          }
                        },
                      );
                    case 2:
                      // Use FutureBuilder for monthly summary
                      return FutureBuilder<Map<String, String>>(
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
                                context, snapshot.data!);
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
  Widget _buildOverallBalancePageContent(
      BuildContext context, Map<String, double> balance) {
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
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Balance amount
                    Text(
                      '\$${netBalance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: balanceColor,
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
                    '\$${totalOwed.toStringAsFixed(2)}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  Text(
                    '\$${totalOwing.toStringAsFixed(2)}',
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
  Widget _buildRecentActivityPageContent(
      BuildContext context, List<dynamic> recentActivity) {
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
            child: _buildRecentActivityList(context, recentActivity),
          ),
        ],
      ),
    );
  }

  // Helper to build the list content or empty state for recent activity
  Widget _buildRecentActivityList(
      BuildContext context, List<dynamic> activityData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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

    // Simplified for now - using original placeholder structure
    // Replace with actual data mapping when available
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: 2, // Using original placeholder count
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: colorScheme.outline.withValues(alpha: 0.1),
        indent: 48, // Aligns with the content after the leading icon
      ),
      itemBuilder: (context, index) {
        // Using placeholder logic as in original
        final isPositive = index == 0;
        final statusColor =
            isPositive ? colorScheme.tertiary : colorScheme.error;

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
                  Icons.receipt_outlined,
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
                      index == 0
                          ? 'Dinner with friends'
                          : 'Movie night', // Placeholder
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      index == 0 ? 'Yesterday' : '3 days ago', // Placeholder
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
                  isPositive ? '+\$24.50' : '-\$12.75', // Placeholder
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
  Widget _buildMonthlySummaryPageContent(
      BuildContext context, Map<String, String> summaryData) {
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
                          'This Month',
                          summaryData['thisMonth'] ?? '\$0.00',
                          Icons.calendar_today_outlined,
                          colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Last month card
                      Expanded(
                        child: _buildCompactMonthlySummaryCard(
                          context,
                          'Last Month',
                          summaryData['lastMonth'] ?? '\$0.00',
                          Icons.calendar_month_outlined,
                          colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Combined action row
                Row(
                  children: [
                    // Trend indicator (placeholder)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              size: 14,
                              color: colorScheme.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '+24%', // Placeholder
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.tertiary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action button
                    Expanded(
                      child: Container(
                        // Make it tappable if needed
                        // InkWell( onTap: () {/* Navigate */}, child: ... )
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
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
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
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius ?? height / 2),
      ),
    );
  }

  Widget _buildSkeletonBox(BuildContext context, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size / 4),
      ),
    );
  }
}

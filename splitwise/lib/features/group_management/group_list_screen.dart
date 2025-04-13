import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/features/expense_tracking/expense_analysis_screen.dart';
import 'package:splitwise/features/group_management/create_group_screen.dart';
import 'package:splitwise/features/group_management/group_detail_screen.dart';
import 'package:splitwise/features/expense_tracking/add_expense_screen.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/group_service.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/features/settings/settings_screen.dart';
import 'package:splitwise/features/profile/profile_screen.dart';
import 'package:splitwise/features/notifications/notification_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  GroupListScreenState createState() => GroupListScreenState();
}

class GroupListScreenState extends State<GroupListScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late GroupService _groupService;
  late ExpenseService _expenseService;
  late UserService _userService;
  late AnimationController _animationController;
  late PageController _balancePageController;
  late AnimationController _balanceCardAnimationController;
  late Animation<double> _balanceCardAnimation;
  late ScrollController _scrollController;
  late ValueNotifier<double> _pagePositionNotifier;
  bool _isScrolled = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Cache for group list data
  List<Group>? _cachedGroups;

  // Animation values
  double _appBarElevation = 0;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
    _expenseService =
        ExpenseService(Provider.of<SettingsService>(context, listen: false));
    _userService = UserService();
    _scrollController = ScrollController();

    // Setup scroll listener for app bar elevation
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 0;
        _appBarElevation = _scrollController.offset > 0 ? 2 : 0;
      });
    });

    // Main animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();

    // Balance card page controller
    _balancePageController = PageController(initialPage: 0);
    _pagePositionNotifier = ValueNotifier<double>(0.0);
    _balancePageController.addListener(() {
      _pagePositionNotifier.value = _balancePageController.page ?? 0;
    });

    // Balance card animation controller
    _balanceCardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _balanceCardAnimation = CurvedAnimation(
      parent: _balanceCardAnimationController,
      curve: Curves.easeInOut,
    );
    _balanceCardAnimationController.forward();

    // Scroll controller for app bar elevation animation
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initialize cache variables
    _cachedBalanceData = null;
    _cachedRecentActivity = null;
    _cachedMonthlySummary = null;
    _isLoadingBalance = false;
    _isLoadingRecentActivity = false;
    _isLoadingMonthlySummary = false;

    // Add listener for app lifecycle changes to handle returning to the app
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is a good place to prefetch data if needed
  }

  @override
  void didUpdateWidget(GroupListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle widget updates if needed
  }

  // We no longer need this method as we're using ValueNotifier

  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    const maxElevation = 4.0;

    // Calculate elevation based on scroll position (max 100px for full elevation)
    final newElevation = (scrollOffset / 100).clamp(0.0, 1.0) * maxElevation;

    if (newElevation != _appBarElevation) {
      setState(() {
        _appBarElevation = newElevation;
        _isScrolled = scrollOffset > 0;
      });
    }
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    _animationController.dispose();
    _searchController.dispose();
    _balancePageController.dispose();
    _balanceCardAnimationController.dispose();
    _scrollController.dispose();
    _pagePositionNotifier.dispose();

    // Clear cache variables
    _cachedBalanceData = null;
    _cachedRecentActivity = null;
    _cachedMonthlySummary = null;
    _cachedGroups = null;
    _groupBalanceCache.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // App is in the foreground and visible to the user
      // Refresh data if needed
      if (mounted) {
        // Clear balance cache to force refresh when returning to the app
        _groupBalanceCache.clear();
      }
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: _isSearching ? 0 : 60,
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: _appBarElevation,
      backgroundColor: _isScrolled
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.98)
          : Theme.of(context).colorScheme.surface,
      leading: Builder(
        builder: (context) => IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSearching
                ? Icon(
                    Icons.arrow_back,
                    key: const ValueKey('back'),
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  )
                : Icon(
                    Icons.menu,
                    key: const ValueKey('menu'),
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 22,
                  ),
          ),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: _isScrolled && !_isSearching
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                : Colors.transparent,
            padding: const EdgeInsets.all(8),
          ),
        ),
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            )
          : null,
      actions: [
        if (!_isSearching)
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
            tooltip: 'Search',
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: _isScrolled
                  ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                  : Colors.transparent,
              padding: const EdgeInsets.all(8),
            ),
          ),
        if (!_isSearching)
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: Theme.of(context).colorScheme.onSurface,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen()));
            },
            tooltip: 'Notifications',
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: _isScrolled
                  ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                  : Colors.transparent,
              padding: const EdgeInsets.all(8),
            ),
          ),
        if (_isSearching && _searchController.text.isNotEmpty)
          IconButton(
            icon: Icon(
              Icons.clear,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
            tooltip: 'Clear',
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: !_isSearching
          ? FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // Cache for balance data to prevent rebuilding when swiping pages
  Map<String, double>? _cachedBalanceData;
  bool _isLoadingBalance = false;

  Widget _buildBalanceOverview(String userId) {
    // If we're already loading or have cached data, use it
    if (_isLoadingBalance && _cachedBalanceData == null) {
      return _buildBalanceOverviewSkeleton();
    }

    // If we don't have cached data, fetch it
    if (_cachedBalanceData == null && !_isLoadingBalance) {
      _isLoadingBalance = true;
      _expenseService.calculateOverallBalance(userId).then((data) {
        if (mounted) {
          setState(() {
            _cachedBalanceData = data;
            _isLoadingBalance = false;
          });
        }
      });
      return _buildBalanceOverviewSkeleton();
    }

    // Use cached data
    final balance = _cachedBalanceData ?? {'owed': 0, 'owing': 0};
    final totalOwed = balance['owed'] ?? 0;
    final totalOwing = balance['owing'] ?? 0;
    final netBalance = totalOwed - totalOwing;

    // Calculate percentage for the progress indicator
    final totalTransactions = totalOwed + totalOwing;
    final owedPercentage =
        totalTransactions > 0 ? totalOwed / totalTransactions : 0.5;

    return AnimatedBuilder(
      animation: _balanceCardAnimation,
      builder: (context, child) {
        return Card(
          elevation: 1,
          shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 222,
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
                          return _buildOverallBalancePage(netBalance, totalOwed,
                              totalOwing, owedPercentage);
                        case 1:
                          return _buildRecentActivityPage(userId);
                        case 2:
                          return _buildMonthlySummaryPage(userId);
                        default:
                          return _buildOverallBalancePage(netBalance, totalOwed,
                              totalOwing, owedPercentage);
                      }
                    },
                  ),
                ),
              ),
              // Use our page indicators widget
              _buildPageIndicators(),
            ],
          ),
        );
      },
    );
  }

  // We'll use a simpler approach with ValueNotifier to avoid full rebuilds
  Widget _buildPageIndicators() {
    return ValueListenableBuilder<double>(
      valueListenable: _pagePositionNotifier,
      builder: (context, pagePosition, _) {
        final currentPage = pagePosition.round();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              // Swipe hint text with animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: 0.3 + (value * 0.7), // Pulsating opacity
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Swipe for more insights',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: currentPage == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallBalancePage(double netBalance, double totalOwed,
      double totalOwing, double owedPercentage) {
    final isPositive = netBalance >= 0;
    final balanceColor = isPositive
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${netBalance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: balanceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 12,
                              color: balanceColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPositive ? 'Net positive' : 'Net negative',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: balanceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Balance progress indicator
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (owedPercentage * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - owedPercentage) * 100).toInt(),
                  child: Container(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'You are owed',
                  totalOwed,
                  Icons.arrow_upward_rounded,
                  Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBalanceItem(
                  'You owe',
                  totalOwing,
                  Icons.arrow_downward_rounded,
                  Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Cache for recent activity data
  List<dynamic>? _cachedRecentActivity;
  bool _isLoadingRecentActivity = false;

  Widget _buildRecentActivityPage(String userId) {
    // Load recent activity data if not already loaded
    if (_cachedRecentActivity == null && !_isLoadingRecentActivity) {
      _isLoadingRecentActivity = true;
      // This would normally call a method to get recent activity
      // For demo purposes, we're just using a placeholder
      Future.delayed(const Duration(milliseconds: 500), () => []).then((data) {
        if (mounted) {
          setState(() {
            _cachedRecentActivity = data;
            _isLoadingRecentActivity = false;
          });
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingRecentActivity
                ? const Center(child: CircularProgressIndicator())
                : _buildRecentActivityContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityContent() {
    if (_cachedRecentActivity == null || _cachedRecentActivity!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    // Simplified for now - would normally show actual activity data
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 2,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            index == 0 ? 'Dinner with friends' : 'Movie night',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          subtitle: Text(
            index == 0 ? 'Yesterday' : '3 days ago',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          trailing: Text(
            index == 0 ? '+\$24.50' : '-\$12.75',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: index == 0
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        );
      },
    );
  }

  // Cache for monthly summary data
  Map<String, String>? _cachedMonthlySummary;
  bool _isLoadingMonthlySummary = false;

  Widget _buildMonthlySummaryPage(String userId) {
    // Load monthly summary data if not already loaded
    if (_cachedMonthlySummary == null && !_isLoadingMonthlySummary) {
      _isLoadingMonthlySummary = true;
      // This would normally call a method to get monthly summary data
      // For demo purposes, we're just using placeholder data
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _cachedMonthlySummary = {
              'thisMonth': '\$245.75',
              'lastMonth': '\$198.30',
            };
            _isLoadingMonthlySummary = false;
          });
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingMonthlySummary
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMonthlySummaryItem(
                            'This Month',
                            _cachedMonthlySummary?['thisMonth'] ?? '\$0.00',
                            Icons.trending_up_rounded,
                            Theme.of(context).colorScheme.tertiary,
                          ),
                          _buildMonthlySummaryItem(
                            'Last Month',
                            _cachedMonthlySummary?['lastMonth'] ?? '\$0.00',
                            Icons.trending_down_rounded,
                            Theme.of(context).colorScheme.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insights_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'View Detailed Analysis',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryItem(
      String label, String amount, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceItem(
      String label, double amount, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '\$${amount.abs().toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildGroupList(String userId, SettingsService settingsService) {
    return StreamBuilder<List<Group>>(
      stream: _groupService.getUserGroups(userId),
      builder: (context, snapshot) {
        // Use cached data while waiting for new data
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_cachedGroups == null) {
            return SliverToBoxAdapter(child: _buildGroupListSkeleton());
          }
          // Use cached data while refreshing
          snapshot = AsyncSnapshot<List<Group>>.withData(
            ConnectionState.done,
            _cachedGroups!,
          );
        } else if (snapshot.hasData) {
          // Update cache with new data
          _cachedGroups = snapshot.data;
          // Don't call setState during build
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        // Filter groups based on search query if searching
        final groups = _searchQuery.isEmpty
            ? snapshot.data!
            : snapshot.data!
                .where((group) => group.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
                .toList();

        if (groups.isEmpty && _searchQuery.isNotEmpty) {
          return SliverToBoxAdapter(child: _buildSearchEmptyState());
        }

        return SliverList(
          // Add a key to help maintain state during scrolling
          key: const PageStorageKey('group_list'),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final group = groups[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildGroupCard(group, userId, settingsService),
                    ),
                  ),
                ),
              );
            },
            childCount: groups.length,
          ),
        );
      },
    );
  }

  // Cache for group balances to prevent unnecessary rebuilds
  final Map<String, double> _groupBalanceCache = {};

  Widget _buildGroupCard(
      Group group, String userId, SettingsService settingsService) {
    // Use a unique key for each group card to maintain state
    return Card(
      key: ValueKey('group_card_${group.id}'),
      elevation: 1,
      shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGroupAvatar(group),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.members.length} members',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            if (group.description.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  group.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildGroupMenu(group, userId),
                ],
              ),
            ),
            // Use a more efficient approach for balance calculation
            FutureBuilder<double>(
              // Use cached balance if available to prevent flickering
              future: _getGroupBalance(group.id, userId),
              builder: (context, balanceSnapshot) {
                // Only show skeleton if we don't have cached data
                if (balanceSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  if (!_groupBalanceCache.containsKey(group.id)) {
                    return _buildBalanceSkeletonIndicator();
                  }
                  // If we have cached data, use it instead of showing skeleton
                }

                final balance =
                    balanceSnapshot.data ?? _groupBalanceCache[group.id] ?? 0;
                final isPositive = balance >= 0;
                final balanceColor = isPositive
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.error;

                return Column(
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: balanceColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPositive
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 16,
                                  color: balanceColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPositive ? 'You are owed' : 'You owe',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\$${balance.abs().toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: balanceColor,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildQuickActionButton(
                                icon: Icons.add_rounded,
                                label: 'Add',
                                onTap: () => _navigateToAddExpense(group),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickActionButton(
                                icon: Icons.receipt_long_outlined,
                                label: 'View',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          GroupDetailScreen(group: group)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get group balance with caching
  Future<double> _getGroupBalance(String groupId, String userId) async {
    // Return cached value immediately if available
    if (_groupBalanceCache.containsKey(groupId)) {
      return _groupBalanceCache[groupId]!;
    }

    // Calculate and cache the balance
    final balance =
        await _expenseService.calculateGroupBalance(groupId, userId);
    _groupBalanceCache[groupId] = balance;
    return balance;
  }

  Widget _buildGroupMenu(Group group, String userId) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'settle',
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('Settle Up'),
            ],
          ),
        ),
        if (group.creatorId == userId)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                const Text('Edit Group'),
              ],
            ),
          ),
        if (group.creatorId == userId)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Delete Group',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'details':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(group: group)),
            );
            break;
          case 'add_expense':
            _navigateToAddExpense(group);
            break;
          case 'settle':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseAnalysisScreen(group: group),
              ),
            );
            break;
          case 'edit':
            // Handle edit action
            break;
          case 'delete':
            _showDeleteGroupDialog(group);
            break;
        }
      },
    );
  }

  void _navigateToAddExpense(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(group: group),
      ),
    ).then((_) {
      // Clear the balance cache for this group when returning from add expense
      if (mounted) {
        setState(() {
          // Only clear the specific group's cache to force a refresh
          _groupBalanceCache.remove(group.id);
        });
      }
    });
  }

  void _showDeleteGroupDialog(Group group) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                'Delete Group',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to delete this group? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteGroup(group);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteGroup(Group group) async {
    try {
      await _groupService.deleteGroup(group.id);
      if (mounted) {
        _showSuccessSnackBar('Group deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete group');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.onTertiary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.onError),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(Group group) {
    final groupColor = _getGroupColor(group.id);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: groupColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: groupColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: groupColor.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  groupColor.withValues(alpha: 0.2),
                  groupColor.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Center(
              child: Text(
                group.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: groupColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: groupColor.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getGroupColor(String groupId) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.inversePrimary,
    ];
    final colorIndex = groupId.hashCode % colors.length;
    return colors[colorIndex];
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated container with illustration
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 70,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.7),
                ),
                Positioned(
                  right: 40,
                  bottom: 40,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      size: 24,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Groups Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Create your first group to start splitting expenses with friends and family. Track who owes what and settle up easily.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ).then((_) {
              if (mounted) {
                setState(() {});
              }
            }),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Create Your First Group'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              // Show a sample group dialog or tutorial
              _showHelpDialog();
            },
            icon: const Icon(Icons.help_outline, size: 16),
            label: const Text('Learn how it works'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'How SplitWise Works',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpStep(
                '1',
                'Create a group',
                'Start by creating a group for your household, trip, or event.',
                Icons.group_add_outlined,
              ),
              const SizedBox(height: 16),
              _buildHelpStep(
                '2',
                'Add members',
                'Invite friends to join your group so you can split expenses.',
                Icons.person_add_outlined,
              ),
              const SizedBox(height: 16),
              _buildHelpStep(
                '3',
                'Add expenses',
                'Record expenses as they happen and assign them to group members.',
                Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 16),
              _buildHelpStep(
                '4',
                'Settle up',
                'See who owes what and settle debts with a few taps.',
                Icons.check_circle_outline,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              ).then((_) {
                if (mounted) {
                  setState(() {});
                }
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Create Group'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildHelpStep(
      String number, String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated search illustration
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withValues(alpha: 0.1),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.search_off_rounded,
                      size: 60,
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.7),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Animated text
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text(
                  'No Results Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'We couldn\'t find any groups matching "$_searchQuery". Try a different search term or check your spelling.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear Search'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                ).then((_) {
                  if (mounted) {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  }
                }),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Group'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceOverviewSkeleton() {
    return Card(
      elevation: 1,
      shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 222,
            child: NotificationListener<ScrollNotification>(
              // Prevent scroll events from propagating to parent
              onNotification: (notification) => true,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSkeletonLine(width: 100, height: 18),
                            const SizedBox(height: 8),
                            _buildSkeletonLine(width: 160, height: 32),
                          ],
                        ),
                        _buildSkeletonBox(size: 40),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSkeletonLine(width: double.infinity, height: 8),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildBalanceItemSkeleton()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildBalanceItemSkeleton()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                // Swipe hint text skeleton
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSkeletonBox(size: 14),
                      const SizedBox(width: 4),
                      _buildSkeletonLine(width: 100, height: 10),
                    ],
                  ),
                ),
                // Page indicators skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: index == 0 ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItemSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSkeletonBox(size: 28),
            const SizedBox(width: 6),
            _buildSkeletonLine(width: 60, height: 12),
          ],
        ),
        const SizedBox(height: 6),
        _buildSkeletonLine(width: 90, height: 18),
      ],
    );
  }

  Widget _buildGroupListSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 1,
            shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonBox(size: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSkeletonLine(width: 140, height: 18),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildSkeletonBox(size: 14),
                                const SizedBox(width: 4),
                                _buildSkeletonLine(width: 80, height: 12),
                                const SizedBox(width: 8),
                                _buildSkeletonBox(size: 3),
                                const SizedBox(width: 8),
                                _buildSkeletonLine(width: 100, height: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildSkeletonBox(size: 24),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildSkeletonBox(size: 32),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSkeletonLine(width: 60, height: 12),
                              const SizedBox(height: 4),
                              _buildSkeletonLine(width: 80, height: 16),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildSkeletonLine(width: 60, height: 28),
                          const SizedBox(width: 8),
                          _buildSkeletonLine(width: 60, height: 28),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  Widget _buildSkeletonBox({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(size / 4),
      ),
    );
  }

  Widget _buildBalanceSkeletonIndicator() {
    return Column(
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildSkeletonBox(size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonLine(width: 60, height: 12),
                      const SizedBox(height: 4),
                      _buildSkeletonLine(width: 80, height: 16),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildSkeletonLine(width: 60, height: 28),
                  const SizedBox(width: 8),
                  _buildSkeletonLine(width: 60, height: 28),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: _buildDrawer(context, authService),
      floatingActionButton: _buildFloatingActionButton(),
      body: CustomScrollView(
        key: const PageStorageKey('group_list_scroll'),
        controller: _scrollController,
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildBalanceOverview(authService.currentUser!.uid),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 04, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Groups',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildGroupList(
              authService.currentUser!.uid,
              settingsService,
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 80),
          ), // Extra padding for FAB
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
      ).then((_) {
        if (mounted) {
          setState(() {});
        }
      }),
      icon: const Icon(Icons.add),
      label: const Text('New Group'),
      elevation: 4,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthService authService) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildDrawerHeader(authService),
          _buildDrawerBody(context, authService),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthService authService) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userService.getUserData(authService.currentUser!.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data ?? {};
        final name = userData['name'] ?? 'User';
        final email = userData['email'] ?? '';
        final profileImageUrl = userData['profileImageUrl'];

        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(profileImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profileImageUrl == null
                            ? Icon(Icons.person,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () =>
                        _navigateToScreen(context, const ProfileScreen()),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawerBody(BuildContext context, AuthService authService) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () => _navigateToScreen(context, const ProfileScreen()),
            ),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => _navigateToScreen(context, const SettingsScreen()),
            ),
            Divider(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.1)),
            _buildDrawerItem(
              icon: Icons.exit_to_app,
              title: 'Sign Out',
              onTap: () => _showSignOutDialog(context, authService),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor ??
                            Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthService authService) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Sign Out',
          style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
              // Handle sign out in the onPressed callback
              _handleSignOut(authService, context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Separate method to handle sign out logic
  Future<void> _handleSignOut(
      AuthService authService, BuildContext context) async {
    // Store a local reference to the navigator before the async gap
    final navigator = Navigator.of(context);
    await authService.signOut();
    if (mounted) {
      navigator.pop();
    }
  }
}

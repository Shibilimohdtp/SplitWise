import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/features/notifications/notification_screen.dart';
import 'package:splitwise/features/group_management/create_group_screen.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/group_service.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/services/notification_service.dart';

// Import our new component widgets
import 'package:splitwise/widgets/home_screen/balance_overview_widget.dart';
import 'package:splitwise/widgets/home_screen/home_app_bar.dart';
import 'package:splitwise/widgets/home_screen/group_list_widget.dart';
import 'package:splitwise/widgets/home_screen/home_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late GroupService _groupService;
  late ExpenseService _expenseService;
  late UserService _userService;
  late NotificationService _notificationService;
  late ScrollController _scrollController;
  bool _isScrolled = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Create a GlobalKey for the Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation values
  double _appBarElevation = 0;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
    _expenseService =
        ExpenseService(Provider.of<SettingsService>(context, listen: false));
    _userService = UserService();
    _notificationService = NotificationService();
    _scrollController = ScrollController();

    // Setup scroll listener for app bar elevation
    _scrollController.addListener(_onScroll);

    // Add listener for app lifecycle changes to handle returning to the app
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is a good place to prefetch data if needed
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle widget updates if needed
  }

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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // App is in the foreground and visible to the user
      // Refresh data if needed
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: HomeDrawer(
        authService: authService,
        userService: _userService,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: CustomScrollView(
        key: const PageStorageKey('group_list_scroll'),
        controller: _scrollController,
        slivers: [
          StreamBuilder<int>(
            stream: _notificationService
                .getUnreadNotificationCount(authService.currentUser!.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData ? snapshot.data! : 0;
              return HomeppBar(
                isSearching: _isSearching,
                isScrolled: _isScrolled,
                appBarElevation: _appBarElevation,
                searchController: _searchController,
                unreadNotificationCount: unreadCount,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
                onSearchToggle: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
                onSearchClear: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                onNotificationTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  );
                },
                onMenuTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: BalanceOverviewWidget(
                userId: authService.currentUser!.uid,
              ),
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
            sliver: GroupListWidget(
              userId: authService.currentUser!.uid,
              settingsService: settingsService,
              expenseService: _expenseService,
              groupService: _groupService,
              searchQuery: _searchQuery,
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
}

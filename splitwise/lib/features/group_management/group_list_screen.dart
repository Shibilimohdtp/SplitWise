import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/features/group_management/create_group_screen.dart';
import 'package:splitwise/features/group_management/group_detail_screen.dart';
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
import 'package:splitwise/utils/app_color.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  _GroupListScreenState createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen>
    with SingleTickerProviderStateMixin {
  late GroupService _groupService;
  late ExpenseService _expenseService;
  late UserService _userService;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
    _expenseService =
        ExpenseService(Provider.of<SettingsService>(context, listen: false));
    _userService = UserService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _isScrolled
          ? AppColors.backgroundLight.withValues(alpha: 0.95)
          : AppColors.backgroundLight,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textMain),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppColors.textMain),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()));
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        title: Text(
          'Split Expenses',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding: EdgeInsets.only(left: 24, bottom: 16),
        centerTitle: false,
      ),
    );
  }

  Widget _buildBalanceOverview(String userId) {
    return FutureBuilder<Map<String, double>>(
      future: _expenseService.calculateOverallBalance(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBalanceOverviewSkeleton();
        }

        final balance = snapshot.data ?? {'owed': 0, 'owing': 0};
        final totalOwed = balance['owed'] ?? 0;
        final totalOwing = balance['owing'] ?? 0;
        final netBalance = totalOwed - totalOwing;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMain.withValues(alpha: 0.05),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${netBalance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color:
                        netBalance >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceItem(
                        'You are owed',
                        totalOwed,
                        Icons.arrow_upward_rounded,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildBalanceItem(
                        'You owe',
                        totalOwing,
                        Icons.arrow_downward_rounded,
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '\$${amount.abs().toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateGroupButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
      ).then((_) => setState(() {})),
      icon:
          const Icon(Icons.add_circle_outline, color: AppColors.secondaryMain),
      label: const Text(
        'New Group',
        style: TextStyle(
          color: AppColors.secondaryMain,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildModernGroupList(String userId, SettingsService settingsService) {
    return StreamBuilder<List<Group>>(
      stream: _groupService.getUserGroups(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: _buildGroupListSkeleton());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final group = snapshot.data![index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child:
                          _buildModernGroupCard(group, userId, settingsService),
                    ),
                  ),
                ),
              );
            },
            childCount: snapshot.data!.length,
          ),
        );
      },
    );
  }

  Widget _buildModernGroupCard(
      Group group, String userId, SettingsService settingsService) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildGroupAvatar(group),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${group.members.length} members',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<double>(
                  future:
                      _expenseService.calculateGroupBalance(group.id, userId),
                  builder: (context, balanceSnapshot) {
                    if (balanceSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildBalanceSkeletonIndicator();
                    }

                    final balance = balanceSnapshot.data ?? 0;
                    final isPositive = balance >= 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            (isPositive ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 16,
                            color: isPositive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPositive ? 'You are owed' : 'You owe',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${balance.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isPositive
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(Group group) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getGroupColor(group.id).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          group.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: _getGroupColor(group.id),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getGroupColor(String groupId) {
    final colors = [
      AppColors.primaryMain,
      AppColors.secondaryMain,
      AppColors.accentMain,
      AppColors.success,
      AppColors.warning,
    ];
    final colorIndex = groupId.hashCode % colors.length;
    return colors[colorIndex];
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.secondaryMain.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_add_outlined,
              size: 80,
              color: AppColors.secondaryMain,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Groups Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create a group to start splitting expenses with your friends',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                'Create Your First Group',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceOverviewSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonLine(width: 100, height: 20),
            const SizedBox(height: 12),
            _buildSkeletonLine(width: 180, height: 40),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildBalanceItemSkeleton()),
                const SizedBox(width: 24),
                Expanded(child: _buildBalanceItemSkeleton()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItemSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSkeletonBox(size: 32),
            const SizedBox(width: 8),
            _buildSkeletonLine(width: 80, height: 16),
          ],
        ),
        const SizedBox(height: 12),
        _buildSkeletonLine(width: 120, height: 24),
      ],
    );
  }

  Widget _buildGroupListSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMain.withValues(alpha: 0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSkeletonBox(size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonLine(width: 150, height: 20),
                          const SizedBox(height: 8),
                          _buildSkeletonLine(width: 100, height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSkeletonLine(width: 200, height: 40),
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
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  Widget _buildSkeletonBox({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(size / 4),
      ),
    );
  }

  Widget _buildBalanceSkeletonIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(12),
      ),
      width: 200,
      height: 40,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: _buildDrawer(context, authService),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            setState(() {
              _isScrolled = scrollNotification.metrics.pixels > 0;
            });
          }
          return true;
        },
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildBalanceOverview(authService.currentUser!.uid),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Groups',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    _buildCreateGroupButton(context),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: _buildModernGroupList(
                authService.currentUser!.uid,
                settingsService,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthService authService) {
    return Drawer(
      child: Container(
        color: AppColors.surfaceLight,
        child: Column(
          children: [
            _buildDrawerHeader(authService),
            _buildDrawerBody(context, authService),
          ],
        ),
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
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryMain,
                    AppColors.primaryDark,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLight,
                      image: profileImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(profileImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: profileImageUrl == null
                        ? const Icon(Icons.person,
                            size: 40, color: AppColors.primaryMain)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
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
      child: Container(
        color: AppColors.surfaceLight,
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
              const Divider(color: AppColors.borderLight),
              _buildDrawerItem(
                icon: Icons.exit_to_app,
                title: 'Sign Out',
                onTap: () => _showSignOutDialog(context, authService),
                textColor: AppColors.error,
                iconColor: AppColors.error,
              ),
            ],
          ),
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
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textMain,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textMain,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _showSignOutDialog(
      BuildContext context, AuthService authService) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: AppColors.surfaceLight,
      ),
    );

    if (result == true) {
      await authService.signOut();
      Navigator.pop(context);
    }
  }
}

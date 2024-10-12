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

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
    _expenseService =
        ExpenseService(Provider.of<SettingsService>(context, listen: false));
    _userService = UserService();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildFinancialOverview(authService.currentUser!.uid),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver:
                _buildGroupList(authService.currentUser!.uid, settingsService),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      drawer: _buildDrawer(context, authService),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryMain,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('My Groups',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primaryMain],
            ),
          ),
          child: Center(
            child: Icon(Icons.group,
                size: 80, color: Colors.white.withOpacity(0.3)),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => NotificationScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateGroupScreen()),
        ).then((_) => setState(() {})),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Create Group', style: TextStyle(color: Colors.white)),
        tooltip: 'Create new group',
        backgroundColor: AppColors.accentMain,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthService authService) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildDrawerHeader(authService),
            _buildDrawerItem(
                Icons.person, 'Profile', () => _navigateToProfile(context)),
            _buildDrawerItem(
                Icons.settings, 'Settings', () => _navigateToSettings(context)),
            _buildDrawerItem(Icons.exit_to_app, 'Sign Out',
                () => _signOut(context, authService)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(AuthService authService) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userService.getUserData(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingDrawerHeader();
        }

        final userData = snapshot.data ?? {};
        final name = userData['name'] ?? 'User';
        final email = userData['email'] ?? '';
        final profileImageUrl = userData['profileImageUrl'];

        return UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primaryMain],
            ),
          ),
          accountName:
              Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          accountEmail: Text(email),
          currentAccountPicture: GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: CircleAvatar(
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : null,
              backgroundColor: AppColors.secondaryLight,
              child: profileImageUrl == null
                  ? Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primaryMain],
        ),
      ),
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryMain),
      title: Text(title, style: TextStyle(color: AppColors.textMain)),
      onTap: onTap,
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    ).then((_) => setState(() {}));
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  Future<void> _signOut(BuildContext context, AuthService authService) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: TextStyle(color: AppColors.textMain)),
        content: Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.textLight)),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text('Sign Out'),
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      await authService.signOut();
      Navigator.pop(context);
    }
  }

  Widget _buildFinancialOverview(String userId) {
    return FutureBuilder<Map<String, double>>(
      future: _expenseService.calculateOverallBalance(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: AppColors.textMain)));
        }

        final balance = snapshot.data!;
        final totalOwed = balance['owed'] ?? 0;
        final totalOwing = balance['owing'] ?? 0;
        final netBalance = totalOwed - totalOwing;

        return Card(
          margin: EdgeInsets.all(16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Overview',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBalanceItem('You are owed', totalOwed, Colors.green),
                    _buildBalanceItem('You owe', totalOwing, Colors.red),
                  ],
                ),
                SizedBox(height: 16),
                _buildBalanceItem('Net balance', netBalance,
                    netBalance >= 0 ? Colors.green : Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceItem(String label, double amount, Color color) {
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textLight)),
        SizedBox(height: 4),
        Text(
          '${settingsService.currency}${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildGroupList(String userId, SettingsService settingsService) {
    return StreamBuilder<List<Group>>(
      stream: _groupService.getUserGroups(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
              child: Center(
                  child: Text('Error: ${snapshot.error}',
                      style: TextStyle(color: AppColors.textMain))));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_add, size: 64, color: AppColors.textLight),
                  SizedBox(height: 16),
                  Text('No groups found. Create one!',
                      style:
                          TextStyle(fontSize: 18, color: AppColors.textLight)),
                ],
              ),
            ),
          );
        }

        return SliverAnimatedList(
          initialItemCount: snapshot.data!.length,
          itemBuilder: (context, index, animation) {
            final group = snapshot.data![index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildGroupCard(group, userId, settingsService),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupCard(
      Group group, String userId, SettingsService settingsService) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textLight),
                ],
              ),
              SizedBox(height: 8),
              Text(
                group.description,
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),
              FutureBuilder<double>(
                future: _expenseService.calculateGroupBalance(group.id, userId),
                builder: (context, balanceSnapshot) {
                  if (balanceSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Text('Calculating balance...',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textLight));
                  }

                  final balance = balanceSnapshot.data ?? 0;
                  final isPositive = balance >= 0;
                  final balanceText =
                      '${settingsService.currency}${balance.abs().toStringAsFixed(2)}';

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPositive ? 'You are owed' : 'You owe',
                        style:
                            TextStyle(fontSize: 14, color: AppColors.textLight),
                      ),
                      Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isPositive ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            balanceText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

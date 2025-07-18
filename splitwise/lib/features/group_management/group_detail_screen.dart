import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/models/user.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/group_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/features/expense_tracking/add_expense_screen.dart';

// Import components
import 'package:splitwise/widgets/group_details_component/group_header.dart';
import 'package:splitwise/widgets/group_details_component/group_balance_card.dart';
import 'package:splitwise/widgets/group_details_component/group_tab_bar.dart';
import 'package:splitwise/widgets/group_details_component/group_members_tab.dart';
import 'package:splitwise/widgets/group_details_component/group_options_bottom_sheet.dart';
import 'package:splitwise/widgets/group_details_component/member_management_dialogs.dart';
import 'package:splitwise/widgets/expense_list_components/expense_list.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  GroupDetailScreenState createState() => GroupDetailScreenState();
}

class GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GroupService _groupService;
  late UserService _userService;
  late AuthService _authService;
  late List<User> _members = [];
  late String _currentUserId;
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _groupService = GroupService();
    _userService = UserService();
    _authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = _authService.currentUser!.uid;
    _loadMembers();
    _loadBalanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final memberUsers =
          await _userService.getGroupMembers(widget.group.memberIds);

      final invitedUsers = widget.group.invitedEmails.map((email) {
        return User(uid: '', name: 'Invited', username: email, email: email);
      }).toList();

      if (mounted) {
        setState(() {
          _members = [...memberUsers, ...invitedUsers];
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
        _showErrorSnackBar('Failed to load members');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onError
                    .withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.onError, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onTertiary
                    .withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline_rounded,
                  color: Theme.of(context).colorScheme.onTertiary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onTertiary))),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Balance data
  double _youAreOwed = 0.0;
  double _youOwe = 0.0;
  double _netBalance = 0.0;
  bool _isLoadingBalance = true;

  Future<void> _loadBalanceData() async {
    try {
      final expenseService =
          Provider.of<ExpenseService>(context, listen: false);
      final balances = await expenseService.calculateBalances(widget.group.id);

      double owed = 0.0;
      double owe = 0.0;

      // Get the current user's balance
      final userBalance = balances[_currentUserId] ?? 0.0;

      // If positive, user is owed money; if negative, user owes money
      if (userBalance > 0) {
        owed = userBalance;
      } else {
        owe = userBalance.abs();
      }

      if (mounted) {
        setState(() {
          _youAreOwed = owed;
          _youOwe = owe;
          _netBalance = userBalance;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
        _showErrorSnackBar('Failed to load balance data');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            GroupHeader(
              group: widget.group,
              memberCount: _members.length,
              onBackPressed: () => Navigator.pop(context),
              showGroupOptions: _showGroupOptions,
            ),
            _isLoadingBalance
                ? _buildLoadingBalanceCard()
                : GroupBalanceCard(
                    youAreOwed: _youAreOwed,
                    youOwe: _youOwe,
                    netBalance: _netBalance,
                  ),
            GroupTabBar(tabController: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExpensesTab(),
                  _buildMembersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildExpensesTab() {
    return KeepAliveWrapper(
      child: ExpenseList(
        groupId: widget.group.id,
        onDeleteExpense: _handleDeleteExpense,
        members: _members,
      ),
    );
  }

  Widget _buildMembersTab() {
    return GroupMembersTab(
      group: widget.group,
      members: _members,
      currentUserId: _currentUserId,
      isLoadingMembers: _isLoadingMembers,
      showAddMemberDialog: _showAddMemberDialog,
      showRemoveMemberDialog: _showRemoveMemberDialog,
    );
  }

  Widget _buildLoadingBalanceCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      color: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Balance Summary',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Calculating...',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Balance Stats Placeholder
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildLoadingStatItem(),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _buildLoadingStatItem(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatItem() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 4),
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 14,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 12,
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(group: widget.group),
          ),
        );
        // Refresh balance data when returning from add expense screen
        if (mounted) {
          _loadBalanceData();
        }
      },
      tooltip: 'Add Expense',
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add_rounded, size: 24),
    );
  }

  void _showGroupOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => GroupOptionsBottomSheet(
        group: widget.group,
        currentUserId: _currentUserId,
        showDeleteGroupDialog: _showDeleteGroupDialog,
      ),
    );
  }

  Future<void> _showAddMemberDialog() async {
    final email = await MemberManagementDialogs.showAddMemberDialog(context);
    if (email != null && mounted) {
      _inviteMember(email);
    }
  }

  Future<void> _showRemoveMemberDialog(User member) async {
    final shouldRemove =
        await MemberManagementDialogs.showRemoveMemberDialog(context, member);
    if (shouldRemove == true && mounted) {
      _removeMember(member.uid);
    }
  }

  Future<void> _showDeleteGroupDialog() async {
    final shouldDelete =
        await MemberManagementDialogs.showDeleteGroupDialog(context);
    if (shouldDelete == true && mounted) {
      _deleteGroup();
    }
  }

  Future<void> _inviteMember(String email) async {
    try {
      await _groupService.inviteMember(widget.group.id, email);
      if (mounted) {
        _loadMembers();
        _showSuccessSnackBar('Invitation sent successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to send invitation');
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    try {
      await _groupService.removeMember(widget.group.id, memberId);
      if (mounted) {
        _loadMembers();
        _showSuccessSnackBar('Member removed successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to remove member');
      }
    }
  }

  Future<void> _deleteGroup() async {
    try {
      await _groupService.deleteGroup(widget.group.id);
      if (mounted) {
        Navigator.pop(context); // Return to groups list
        _showSuccessSnackBar('Group deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete group');
      }
    }
  }

  Future<void> _handleDeleteExpense(String expenseId) async {
    try {
      await _groupService.deleteExpense(widget.group.id, expenseId);
      if (mounted) {
        _showSuccessSnackBar('Expense deleted successfully');
        // Refresh balance data after deleting an expense
        _loadBalanceData();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete expense');
      }
    }
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

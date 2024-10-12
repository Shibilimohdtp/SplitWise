import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/models/user.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/group_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/features/expense_tracking/add_expense_screen.dart';
import 'package:splitwise/utils/app_color.dart';
import 'package:splitwise/widgets/expense_list.dart';
import 'package:splitwise/features/expense_tracking/expense_analysis_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  GroupDetailScreen({required this.group});

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late GroupService _groupService;
  late UserService _userService;
  late AuthService _authService;
  late List<User> _members = [];
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
    _userService = UserService();
    _authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = _authService.currentUser!.uid;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await _userService.getGroupMembers(widget.group.members);
    setState(() {
      _members = members;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildGroupInfo(),
          ),
          SliverToBoxAdapter(
            child: _buildMembersList(),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Expenses',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: ExpenseList(
              groupId: widget.group.id,
              onDeleteExpense: _deleteExpense,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(group: widget.group),
          ),
        ),
        icon: Icon(Icons.add, color: AppColors.backgroundLight),
        label: Text('Add Expense',
            style: TextStyle(color: AppColors.backgroundLight)),
        backgroundColor: AppColors.accentMain,
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryLight, AppColors.primaryMain],
                ),
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: TextStyle(
                      color: AppColors.backgroundLight,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.group.description,
                    style: TextStyle(
                      color: AppColors.backgroundLight.withOpacity(0.8),
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.analytics, color: AppColors.backgroundLight),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseAnalysisScreen(group: widget.group),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupInfo() {
    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.group.description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.person_add, color: AppColors.accentMain),
                  onPressed: () => _showInviteMemberDialog(context),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl == null
                      ? Text(member.name[0].toUpperCase())
                      : null,
                  backgroundColor: member.profileImageUrl == null
                      ? Colors.primaries[index % Colors.primaries.length]
                      : null,
                ),
                title: Text(
                  member.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                subtitle: Text(
                  member.email,
                  style: TextStyle(color: AppColors.textLight),
                ),
                trailing: (widget.group.creatorId == _currentUserId &&
                        member.uid != _currentUserId)
                    ? IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => _showRemoveMemberDialog(member),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showInviteMemberDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invite Member'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Enter member's email",
              prefixIcon: Icon(Icons.email, color: AppColors.accentMain),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accentMain),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accentMain, width: 2),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textLight),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Invite'),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.backgroundLight,
                backgroundColor: AppColors.accentMain,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                final email = _controller.text;
                if (email.isNotEmpty) {
                  try {
                    await _groupService.inviteMember(widget.group.id, email);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invitation sent successfully'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.accentMain,
                      ),
                    );
                    _loadMembers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send invitation'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRemoveMemberDialog(User member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Member'),
          content: Text(
            'Are you sure you want to remove ${member.name} from the group?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textLight),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Remove'),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.backgroundLight,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                try {
                  await _groupService.removeMember(widget.group.id, member.uid);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Member removed successfully'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.accentMain,
                    ),
                  );
                  _loadMembers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove member'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      await _groupService.deleteExpense(widget.group.id, expenseId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense deleted successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.accentMain,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete expense'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

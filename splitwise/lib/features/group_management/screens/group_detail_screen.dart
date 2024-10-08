import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/models/user.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/group_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/features/expense_tracking/screens/add_expense_screen.dart';
import 'package:splitwise/widgets/expense_list.dart';
import 'package:splitwise/features/expense_tracking/screens/expense_analysis_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
    _userService = UserService();
    _authService = Provider.of<AuthService>(context, listen: false);
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
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseAnalysisScreen(group: widget.group),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildGroupInfo(),
            ),
            SliverToBoxAdapter(
              child: _buildMembersList(),
            ),
            SliverFillRemaining(
              child: ExpenseList(
                groupId: widget.group.id,
                onDeleteExpense: _deleteExpense,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(group: widget.group),
          ),
        ),
        icon: Icon(Icons.add),
        label: Text('Add Expense'),
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(widget.group.description),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  icon: Icon(Icons.person_add),
                  label: Text('Invite'),
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
                  child: Text(member.name[0].toUpperCase()),
                ),
                title: Text(member.name),
                subtitle: Text(member.email),
                trailing: member.uid != widget.group.creatorId
                    ? IconButton(
                        icon: Icon(Icons.remove_circle_outline),
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
            decoration: InputDecoration(hintText: "Enter member's email"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Invite'),
              onPressed: () async {
                final email = _controller.text;
                if (email.isNotEmpty) {
                  try {
                    await _groupService.inviteMember(widget.group.id, email);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invitation sent successfully'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _loadMembers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send invitation'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
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
              'Are you sure you want to remove ${member.name} from the group?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Remove'),
              onPressed: () async {
                try {
                  await _groupService.removeMember(widget.group.id, member.uid);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Member removed successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  _loadMembers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove member'),
                      behavior: SnackBarBehavior.floating,
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
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete expense'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

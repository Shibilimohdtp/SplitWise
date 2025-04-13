import 'package:flutter/material.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/features/group_management/group_detail_screen.dart';
import 'package:splitwise/features/expense_tracking/add_expense_screen.dart';
import 'package:splitwise/features/expense_tracking/expense_analysis_screen.dart';

class GroupCardWidget extends StatefulWidget {
  final Group group;
  final String userId;
  final SettingsService settingsService;
  final ExpenseService expenseService;
  final Function(Group) onDeleteGroup;

  const GroupCardWidget({
    super.key,
    required this.group,
    required this.userId,
    required this.settingsService,
    required this.expenseService,
    required this.onDeleteGroup,
  });

  @override
  GroupCardWidgetState createState() => GroupCardWidgetState();
}

class GroupCardWidgetState extends State<GroupCardWidget> {
  double? _cachedBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('group_card_${widget.group.id}'),
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
          MaterialPageRoute(
              builder: (_) => GroupDetailScreen(group: widget.group)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGroupAvatar(widget.group),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
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
                              '${widget.group.members.length} members',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            if (widget.group.description.isNotEmpty) ...[
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
                                  widget.group.description,
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
                  _buildGroupMenu(widget.group, widget.userId),
                ],
              ),
            ),
            // Use a more efficient approach for balance calculation
            FutureBuilder<double>(
              // Use cached balance if available to prevent flickering
              future: _getGroupBalance(),
              builder: (context, balanceSnapshot) {
                // Only show skeleton if we don't have cached data
                if (balanceSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  if (_cachedBalance == null) {
                    return _buildBalanceSkeletonIndicator();
                  }
                  // If we have cached data, use it instead of showing skeleton
                }

                final balance = balanceSnapshot.data ?? _cachedBalance ?? 0;
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
                                onTap: () => _navigateToAddExpense(),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickActionButton(
                                icon: Icons.receipt_long_outlined,
                                label: 'View',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => GroupDetailScreen(
                                          group: widget.group)),
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
  Future<double> _getGroupBalance() async {
    // Return cached value immediately if available
    if (_cachedBalance != null) {
      return _cachedBalance!;
    }

    // Calculate and cache the balance
    try {
      final balance = await widget.expenseService
          .calculateGroupBalance(widget.group.id, widget.userId);

      if (mounted) {
        setState(() {
          _cachedBalance = balance;
        });
      }
      return balance;
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
      return 0;
    }
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
            _navigateToAddExpense();
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

  void _navigateToAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(group: widget.group),
      ),
    ).then((_) {
      // Clear the balance cache for this group when returning from add expense
      if (mounted) {
        setState(() {
          // Clear the cached balance to force a refresh
          _cachedBalance = null;
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
                        widget.onDeleteGroup(group);
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
}

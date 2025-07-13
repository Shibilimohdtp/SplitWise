import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/group_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/widgets/home_screen/group_card_widget.dart';
import 'package:splitwise/widgets/home_screen/empty_states.dart';

class GroupListWidget extends StatefulWidget {
  final String userId;
  final SettingsService settingsService;
  final ExpenseService expenseService;
  final GroupService groupService;
  final String searchQuery;

  const GroupListWidget({
    super.key,
    required this.userId,
    required this.settingsService,
    required this.expenseService,
    required this.groupService,
    required this.searchQuery,
  });

  @override
  GroupListWidgetState createState() => GroupListWidgetState();
}

class GroupListWidgetState extends State<GroupListWidget> {
  // Cache for group list data
  List<Group>? _cachedGroups;

  @override
  Widget build(BuildContext context) {
    return _buildGroupList();
  }

  Widget _buildGroupList() {
    return StreamBuilder<List<Group>>(
      stream: widget.groupService.getUserGroups(widget.userId),
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
          return SliverToBoxAdapter(
              child: EmptyStates.buildEmptyState(context));
        }

        // Filter groups based on search query if searching
        final groups = widget.searchQuery.isEmpty
            ? snapshot.data!
            : snapshot.data!
                .where((group) => group.name
                    .toLowerCase()
                    .contains(widget.searchQuery.toLowerCase()))
                .toList();

        if (groups.isEmpty && widget.searchQuery.isNotEmpty) {
          return SliverToBoxAdapter(
              child: EmptyStates.buildSearchEmptyState(
                  context, widget.searchQuery));
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
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GroupCardWidget(
                        group: group,
                        userId: widget.userId,
                        settingsService: widget.settingsService,
                        expenseService: widget.expenseService,
                        onDeleteGroup: _handleDeleteGroup,
                      ),
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

  Future<void> _handleDeleteGroup(Group group) async {
    try {
      await widget.groupService.deleteGroup(group.id);
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

  Widget _buildGroupListSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
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
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  Widget _buildSkeletonBox({required double size}) {
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

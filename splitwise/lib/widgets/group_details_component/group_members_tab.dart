import 'package:flutter/material.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/models/user.dart';

class GroupMembersTab extends StatelessWidget {
  final Group group;
  final List<User> members;
  final String currentUserId;
  final bool isLoadingMembers;
  final VoidCallback showAddMemberDialog;
  final Function(User) showRemoveMemberDialog;

  const GroupMembersTab({
    super.key,
    required this.group,
    required this.members,
    required this.currentUserId,
    required this.isLoadingMembers,
    required this.showAddMemberDialog,
    required this.showRemoveMemberDialog,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildMembersHeader(context),
        const SizedBox(height: 12),
        ...members.map((member) => _buildMemberCard(context, member)),
      ],
    );
  }

  Widget _buildMembersHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${members.length} Members',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        if (group.creatorId == currentUserId)
          TextButton.icon(
            onPressed: showAddMemberDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('Invite'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMemberCard(BuildContext context, User member) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCurrentUser = member.uid == currentUserId;
    final isCreator = member.uid == group.creatorId;
    final canRemove = group.creatorId == currentUserId && !isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(context, member, isCurrentUser, isCreator),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isCurrentUser) _buildTag(context, 'You', colorScheme.primary),
          if (isCreator && !isCurrentUser)
            _buildTag(context, 'Admin', colorScheme.tertiary),
          if (canRemove)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                color: colorScheme.error,
                size: 22,
              ),
              onPressed: () => showRemoveMemberDialog(member),
              tooltip: 'Remove Member',
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
      BuildContext context, User member, bool isCurrentUser, bool isCreator) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor:
              colorScheme.primary.withValues(alpha: isCurrentUser ? 0.2 : 0.1),
          backgroundImage: member.profileImageUrl != null
              ? NetworkImage(member.profileImageUrl!)
              : null,
          child: member.profileImageUrl == null
              ? Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (isCreator)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colorScheme.tertiary,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.surface,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.star_rounded,
              size: 10,
              color: colorScheme.onTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

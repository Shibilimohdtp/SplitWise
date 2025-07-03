import 'package:flutter/material.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/widgets/form/section_card.dart';
import 'package:splitwise/widgets/form/section_header.dart';

class ParticipantsSection extends StatelessWidget {
  final Group group;
  final UserService userService;
  final Map<String, bool> participants;
  final Function(String, bool) onParticipantToggled;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  const ParticipantsSection({
    super.key,
    required this.group,
    required this.userService,
    required this.participants,
    required this.onParticipantToggled,
    required this.onSelectAll,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildParticipantsList(context),
          const SizedBox(height: 8),
          _buildSelectionSummary(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SectionHeader(
          title: 'Participants',
          icon: Icons.group_outlined,
          padding: EdgeInsets.zero,
        ),
        _buildQuickActions(context),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            context,
            label: 'All',
            icon: Icons.select_all,
            onTap: onSelectAll,
            color: Theme.of(context).colorScheme.primary,
          ),
          Container(
            width: 1,
            height: 24,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildActionButton(
            context,
            label: 'None',
            icon: Icons.clear_all,
            onTap: onClearAll,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary(BuildContext context) {
    final selectedCount =
        participants.values.where((selected) => selected).length;
    final totalCount = participants.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: selectedCount > 0
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedCount > 0
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selectedCount > 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              shape: BoxShape.circle,
            ),
            child: Text(
              selectedCount.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: selectedCount > 0
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedCount == 0
                      ? 'No participants selected'
                      : selectedCount == 1
                          ? '1 participant selected'
                          : '$selectedCount participants selected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedCount > 0
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (selectedCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'out of $totalCount total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (selectedCount > 0)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(BuildContext context) {
    final allMembers = [...group.memberIds, ...group.invitedEmails];
    return Column(
      children: [
        ...allMembers.map((memberIdentifier) {
          final isInvited = group.invitedEmails.contains(memberIdentifier);
          return FutureBuilder<String>(
            future: isInvited
                ? Future.value(memberIdentifier)
                : userService.getUserName(memberIdentifier),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Loading...';
              final isSelected = participants[memberIdentifier] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.05)
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.05),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3)
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    onParticipantToggled(memberIdentifier, !isSelected);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            onParticipantToggled(memberIdentifier, value!);
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                          checkColor: Theme.of(context).colorScheme.onPrimary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

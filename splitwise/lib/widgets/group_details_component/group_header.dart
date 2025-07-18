import 'package:flutter/material.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/features/expense_tracking/expense_analysis_screen.dart';

class GroupHeader extends StatelessWidget {
  final Group group;
  final int memberCount;
  final VoidCallback onBackPressed;
  final VoidCallback showGroupOptions;

  const GroupHeader({
    super.key,
    required this.group,
    required this.memberCount,
    required this.onBackPressed,
    required this.showGroupOptions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconButton(
                context,
                icon: Icons.arrow_back,
                onPressed: onBackPressed,
                tag: 'back_button_${group.id}',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'group_name_${group.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          group.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (group.description.isNotEmpty) ...[
                      Text(
                        group.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  _buildIconButton(
                    context,
                    icon: Icons.analytics_outlined,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseAnalysisScreen(group: group),
                      ),
                    ),
                    tooltip: 'View Analytics',
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    context,
                    icon: Icons.more_vert_rounded,
                    onPressed: showGroupOptions,
                    tooltip: 'More Options',
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.group_rounded,
                        size: 14,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$memberCount members',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    String? tag,
  }) {
    final button = Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );

    final Widget buttonWithTooltip = tooltip != null
        ? Tooltip(
            message: tooltip,
            child: button,
          )
        : button;

    return tag != null
        ? Hero(tag: tag, child: buttonWithTooltip)
        : buttonWithTooltip;
  }
}

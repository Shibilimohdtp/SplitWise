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
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Hero(
                tag: 'back_button_${group.id}',
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 22),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onBackPressed,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Hero(
                  tag: 'group_name_${group.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.analytics_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 22),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseAnalysisScreen(group: group),
                  ),
                ),
                tooltip: 'View Analytics',
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.more_vert_rounded,
                    color: Theme.of(context).colorScheme.onSurface, size: 22),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: showGroupOptions,
                tooltip: 'More Options',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.group_rounded,
                        size: 14,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$memberCount members',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              fontWeight: FontWeight.w500,
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
}

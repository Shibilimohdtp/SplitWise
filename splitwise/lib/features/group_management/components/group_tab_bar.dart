import 'package:flutter/material.dart';

class GroupTabBar extends StatelessWidget {
  final TabController tabController;

  const GroupTabBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
        unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        splashBorderRadius: BorderRadius.circular(12),
        tabs: const [
          Tab(
            height: 30,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_rounded, size: 18),
                SizedBox(width: 8),
                Text('Expenses'),
              ],
            ),
          ),
          Tab(
            height: 30,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_rounded, size: 18),
                SizedBox(width: 8),
                Text('Members'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

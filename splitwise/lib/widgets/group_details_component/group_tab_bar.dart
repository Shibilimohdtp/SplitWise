import 'package:flutter/material.dart';

class GroupTabBar extends StatelessWidget {
  final TabController tabController;

  const GroupTabBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final outlineColor = colorScheme.outline.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: colorScheme.primary,
        indicatorWeight: 0, // Hidden by BoxDecoration indicator
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        splashBorderRadius: BorderRadius.circular(8),
        tabs: const [
          Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_rounded, size: 16),
                SizedBox(width: 6),
                Text('Expenses'),
              ],
            ),
          ),
          Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_rounded, size: 16),
                SizedBox(width: 6),
                Text('Members'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

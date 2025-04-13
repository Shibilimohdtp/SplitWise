import 'package:flutter/material.dart';

class HomeppBar extends StatelessWidget {
  final bool isSearching;
  final bool isScrolled;
  final double appBarElevation;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchToggle;
  final VoidCallback onSearchClear;
  final VoidCallback onNotificationTap;
  final VoidCallback onMenuTap;

  const HomeppBar({
    super.key,
    required this.isSearching,
    required this.isScrolled,
    required this.appBarElevation,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchToggle,
    required this.onSearchClear,
    required this.onNotificationTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: isSearching ? 0 : 60,
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: appBarElevation,
      backgroundColor: isScrolled
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.98)
          : Theme.of(context).colorScheme.surface,
      leading: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSearching
              ? Icon(
                  Icons.arrow_back,
                  key: const ValueKey('back'),
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                )
              : Icon(
                  Icons.menu,
                  key: const ValueKey('menu'),
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 22,
                ),
        ),
        onPressed: isSearching ? onSearchClear : onMenuTap,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: isScrolled && !isSearching
              ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
              : Colors.transparent,
          padding: const EdgeInsets.all(8),
        ),
      ),
      title: isSearching
          ? TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              onChanged: onSearchChanged,
            )
          : null,
      actions: [
        if (!isSearching)
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface,
              size: 22,
            ),
            onPressed: onSearchToggle,
            tooltip: 'Search',
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isScrolled
                  ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                  : Colors.transparent,
              padding: const EdgeInsets.all(8),
            ),
          ),
        if (!isSearching)
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: Theme.of(context).colorScheme.onSurface,
              size: 22,
            ),
            onPressed: onNotificationTap,
            tooltip: 'Notifications',
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isScrolled
                  ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                  : Colors.transparent,
              padding: const EdgeInsets.all(8),
            ),
          ),
        if (isSearching && searchController.text.isNotEmpty)
          IconButton(
            icon: Icon(
              Icons.clear,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: onSearchClear,
            tooltip: 'Clear',
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: !isSearching
          ? FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

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
  final int? unreadNotificationCount;

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
    this.unreadNotificationCount,
  });

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
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
        if (unreadNotificationCount != null && unreadNotificationCount! > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  unreadNotificationCount! > 9
                      ? '9+'
                      : unreadNotificationCount!.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

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
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
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
        if (!isSearching) _buildNotificationButton(context),
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

import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
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

  const HomeAppBar({
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
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            color: colorScheme.onSurface,
            size: 24,
          ),
          onPressed: onNotificationTap,
          tooltip: 'Notifications',
          style: _iconButtonStyle(context),
        ),
        if (unreadNotificationCount != null && unreadNotificationCount! > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  unreadNotificationCount! > 9
                      ? '9+'
                      : unreadNotificationCount!.toString(),
                  style: TextStyle(
                    color: colorScheme.onError,
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

  ButtonStyle _iconButtonStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton.styleFrom(
      foregroundColor: colorScheme.onSurface,
      backgroundColor: isScrolled
          ? colorScheme.surface.withValues(alpha: 0.8)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverAppBar(
      expandedHeight: isSearching ? 0 : 60,
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: appBarElevation,
      backgroundColor: isScrolled
          ? colorScheme.surface.withValues(alpha: 0.98)
          : colorScheme.surface,
      leading: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: isSearching
              ? Icon(
                  Icons.arrow_back_ios_new_rounded,
                  key: const ValueKey('back'),
                  color: colorScheme.primary,
                  size: 22,
                )
              : Icon(
                  Icons.menu_rounded,
                  key: const ValueKey('menu'),
                  color: colorScheme.onSurface,
                  size: 24,
                ),
        ),
        onPressed: isSearching ? onSearchClear : onMenuTap,
        style: _iconButtonStyle(context),
      ),
      title: isSearching
          ? TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              onChanged: onSearchChanged,
            )
          : null,
      actions: [
        if (!isSearching)
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: colorScheme.onSurface,
              size: 24,
            ),
            onPressed: onSearchToggle,
            tooltip: 'Search',
            style: _iconButtonStyle(context),
          ),
        if (!isSearching) _buildNotificationButton(context),
        if (isSearching && searchController.text.isNotEmpty)
          IconButton(
            icon: Icon(
              Icons.clear_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
            onPressed: onSearchClear,
            tooltip: 'Clear',
            style: _iconButtonStyle(context),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

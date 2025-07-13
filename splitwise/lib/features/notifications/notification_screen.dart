import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/features/settings/settings_screen.dart';
import 'package:splitwise/models/notification.dart' as model;
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays <= 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  Widget _buildNotificationIcon(bool isRead) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRead
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isRead ? 0.1 : 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        isRead ? Icons.notifications_outlined : Icons.notifications,
        color: colorScheme.primary,
        size: 18,
      ),
    );
  }

  Future<void> _toggleReadStatus(model.Notification notification) async {
    await _notificationService.toggleNotificationReadStatus(
      notification.id,
      notification.isRead,
    );
  }

  Future<void> _markAllAsRead(String userId) async {
    await _notificationService.markAllNotificationsAsRead(userId);
    if (mounted) {
      _showMarkAllReadSnackBar();
    }
  }

  void _showMarkAllReadSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String userId) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      title: Text(
        'Notifications',
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: 0.1,
        ),
      ),
      leading: _buildBackButton(),
      actions: [
        _buildMarkAllReadButton(userId),
        _buildSettingsButton(),
      ],
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back, size: 20),
      onPressed: () => Navigator.pop(context),
      iconSize: 20,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildMarkAllReadButton(String userId) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<model.Notification>>(
      stream: _notificationService.getUserNotifications(userId),
      builder: (context, snapshot) {
        final hasUnreadNotifications = snapshot.hasData &&
            snapshot.data!.any((notification) => !notification.isRead);

        return Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: Icon(
              Icons.done_all,
              color: hasUnreadNotifications
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 20,
            ),
            onPressed:
                hasUnreadNotifications ? () => _markAllAsRead(userId) : null,
            tooltip: 'Mark all as read',
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.all(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Icon(
          Icons.settings_outlined,
          color: colorScheme.onSurface,
          size: 20,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "You're all caught up!",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No new notifications at the moment",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<model.Notification> notifications) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(model.Notification notification) {
    return Dismissible(
      key: Key(notification.id),
      background: _buildDismissBackground(notification),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _toggleReadStatus(notification);
        return false; // Don't actually dismiss the item
      },
      child: _buildNotificationCard(notification),
    );
  }

  Widget _buildDismissBackground(model.Notification notification) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20.0),
      margin: const EdgeInsets.fromLTRB(0, 2, 0, 10),
      decoration: BoxDecoration(
        color:
            notification.isRead ? colorScheme.primary : colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        notification.isRead
            ? Icons.mark_email_unread_outlined
            : Icons.mark_email_read_outlined,
        color: colorScheme.onPrimary,
        size: 20,
      ),
    );
  }

  Widget _buildNotificationCard(model.Notification notification) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.isRead
            ? colorScheme.surface
            : colorScheme.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? colorScheme.outline.withValues(alpha: 0.2)
              : colorScheme.primary.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onNotificationTap(notification),
          onLongPress: () => _toggleReadStatus(notification),
          child: _buildNotificationContent(notification),
        ),
      ),
    );
  }

  void _onNotificationTap(model.Notification notification) {
    // Mark as read when tapped
    if (!notification.isRead) {
      _notificationService.markNotificationAsRead(notification.id);
    }
  }

  Widget _buildNotificationContent(model.Notification notification) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationIcon(notification.isRead),
          const SizedBox(width: 16),
          Expanded(
            child: _buildNotificationDetails(notification),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDetails(model.Notification notification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNotificationHeader(notification),
        const SizedBox(height: 6),
        _buildNotificationBody(notification),
      ],
    );
  }

  Widget _buildNotificationHeader(model.Notification notification) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            notification.title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight:
                  notification.isRead ? FontWeight.w500 : FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: 0.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            if (!notification.isRead) _buildUnreadIndicator(),
            Text(
              _formatTime(notification.createdAt),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnreadIndicator() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildNotificationBody(model.Notification notification) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      notification.body,
      style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
        fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser!.uid;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(userId),
      body: StreamBuilder<List<model.Notification>>(
        stream: _notificationService.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNotificationsList(snapshot.data!);
        },
      ),
    );
  }
}

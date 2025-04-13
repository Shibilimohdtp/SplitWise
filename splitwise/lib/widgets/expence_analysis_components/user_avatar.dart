import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A reusable widget for displaying user avatars with profile images or fallback initials.
class UserAvatar extends StatelessWidget {
  /// The user's ID used to fetch profile data if needed
  final String? userId;

  /// The user's name for displaying initials as fallback
  final String userName;

  /// URL to the user's profile image
  final String? profileImageUrl;

  /// Radius of the avatar circle
  final double radius;

  /// Background color when showing initials
  final Color? backgroundColor;

  /// Text color for the initials
  final Color? foregroundColor;

  /// Shadow color for the avatar
  final Color? shadowColor;

  /// Whether to show a shadow
  final bool showShadow;

  /// Border color for the avatar
  final Color? borderColor;

  /// Border width for the avatar
  final double? borderWidth;

  const UserAvatar({
    super.key,
    this.userId,
    required this.userName,
    this.profileImageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.shadowColor,
    this.showShadow = false,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor =
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    final defaultForegroundColor = Theme.of(context).colorScheme.primary;
    final defaultShadowColor = Colors.black.withValues(alpha: 0.1);

    // Determine the initial to display as fallback
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    // Calculate font size based on radius
    final fontSize = radius * 0.7;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? defaultBackgroundColor,
        border: (borderColor != null && borderWidth != null)
            ? Border.all(color: borderColor!, width: borderWidth!)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: shadowColor ?? defaultShadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: profileImageUrl != null && profileImageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: profileImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: defaultForegroundColor.withValues(alpha: 0.5),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: foregroundColor ?? defaultForegroundColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: foregroundColor ?? defaultForegroundColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

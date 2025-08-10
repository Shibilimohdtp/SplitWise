import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splitwise/constants/app_color.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/features/expense_tracking/expense_analysis_screen.dart';

class GroupOptionsBottomSheet extends StatelessWidget {
  final Group group;
  final String currentUserId;
  final VoidCallback showDeleteGroupDialog;

  const GroupOptionsBottomSheet({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.showDeleteGroupDialog,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Group Options',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Options
            _buildOptionTile(
              context: context,
              icon: Icons.analytics_rounded,
              title: 'View Analytics',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseAnalysisScreen(group: group),
                  ),
                );
              },
            ),
            _buildOptionTile(
              context: context,
              icon: Icons.share_rounded,
              title: 'Share Group',
              onTap: () {
                Navigator.pop(context);
                _shareGroupWithImage(context, group);
              },
            ),
            if (group.creatorId == currentUserId)
              _buildOptionTile(
                context: context,
                icon: Icons.delete_rounded,
                title: 'Delete Group',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  showDeleteGroupDialog();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _shareGroupWithImage(BuildContext context, Group group) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final String shareUrl =
          'https://splitwise-join.netlify.app?id=${group.id}';

      // Generate the invitation image
      final Uint8List? imageBytes =
          await _generateInvitationImage(context, group, shareUrl);

      // Hide loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (imageBytes == null) {
        throw Exception('Failed to generate invitation image');
      }

      // Save image to temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'splitwise_invitation_${group.id}.png';
      final File imageFile = File('${tempDir.path}/$fileName');
      await imageFile.writeAsBytes(imageBytes);

      // Share the image with text
      final String shareText =
          'Scan the QR code or use this link to join the gruop:\n\n$shareUrl';

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: shareText,
        subject: 'Splitwise Group Invitation - ${group.name}',
      );
    } catch (e) {
      // Hide loading indicator if still showing
      if (context.mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create invitation: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _generateInvitationImage(
    BuildContext context,
    Group group,
    String shareUrl,
  ) async {
    try {
      final GlobalKey repaintBoundaryKey = GlobalKey();

      // Create a completer to wait for the widget to be built
      final Completer<Uint8List?> completer = Completer<Uint8List?>();

      // Create overlay entry to render the widget
      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -1000, // Position off-screen
          top: -1000,
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              key: repaintBoundaryKey,
              child: GroupInvitationCard(
                group: group,
                shareUrl: shareUrl,
              ),
            ),
          ),
        ),
      );

      // Insert overlay
      Overlay.of(context).insert(overlayEntry);

      // Wait for next frame to ensure widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Add small delay to ensure rendering is complete
          await Future.delayed(const Duration(milliseconds: 100));

          final RenderRepaintBoundary? boundary =
              repaintBoundaryKey.currentContext?.findRenderObject()
                  as RenderRepaintBoundary?;

          if (boundary == null) {
            completer.complete(null);
            return;
          }

          // Convert to image
          final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
          final ByteData? byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );

          // Remove overlay
          overlayEntry.remove();

          if (byteData != null) {
            completer.complete(byteData.buffer.asUint8List());
          } else {
            completer.complete(null);
          }
        } catch (e) {
          overlayEntry.remove();
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;
    final textColor = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupInvitationCard extends StatelessWidget {
  final Group group;
  final String shareUrl;

  const GroupInvitationCard({
    super.key,
    required this.group,
    required this.shareUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryMainDarkTheme.withValues(alpha: 0.9),
            AppColors.backgroundDarkTheme,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderLightDarkTheme.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minimal brand header
            const Row(
              children: [
                Icon(
                  Icons.splitscreen_rounded,
                  color: AppColors.primaryLightDarkTheme,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Splitwise',
                  style: TextStyle(
                    color: AppColors.primaryLightDarkTheme,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Clean invitation text
            const Text(
              "You're invited to join",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: AppColors.textMainDarkTheme,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Group name with minimal styling
            Text(
              group.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 48),

            // Clean QR code container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: QrImageView(
                data: shareUrl,
                version: QrVersions.auto,
                size: 140,
                gapless: false,
              ),
            ),

            const SizedBox(height: 32),

            // Simplified instruction text
            Text(
              'Scan to join or share the link',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDarkTheme.withValues(alpha: 0.9),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Subtle divider
            Container(
              width: 40,
              height: 1,
              color: AppColors.borderLightDarkTheme.withValues(alpha: 0.3),
            ),

            const SizedBox(height: 24),

            // Clean footer text
            Text(
              'Split expenses effortlessly',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryDarkTheme.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

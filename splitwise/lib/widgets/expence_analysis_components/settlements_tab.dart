import 'package:flutter/material.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/widgets/expence_analysis_components/user_avatar.dart';
import 'package:splitwise/features/expense_tracking/models/expense_analysis_models.dart';
import 'package:splitwise/widgets/common/animated_wrapper.dart';
import 'package:splitwise/widgets/expence_analysis_components/future_content_builder.dart';
import 'package:splitwise/utils/currency_utils.dart';

class SettlementsTab extends StatefulWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;
  final UserService userService;
  final BorderSide outlineBorderSide;
  final VoidCallback onSettlementCompleted;

  const SettlementsTab({
    super.key,
    required this.group,
    required this.expenseService,
    required this.settingsService,
    required this.userService,
    required this.outlineBorderSide,
    required this.onSettlementCompleted,
  });

  @override
  SettlementsTabState createState() => SettlementsTabState();
}

class SettlementsTabState extends State<SettlementsTab> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            colorScheme,
            textTheme,
            icon: Icons.handshake_outlined,
            title: 'Suggested Settlements',
            subtitle: 'Plan to settle debts',
            primaryColor: colorScheme.tertiary,
            badgeText: 'Settlements',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureContentBuilder<Map<String, double>>(
                future:
                    widget.expenseService.calculateBalances(widget.group.id),
                loadingMessage: 'Calculating settlements...',
                builder: (context, balances) {
                  final settlements = calculateSettlements(balances);
                  if (settlements.isEmpty) {
                    return _buildAllSettledMessage(
                        context, colorScheme, textTheme);
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                              bottom: 10), // Add padding for the fixed card
                          itemCount: settlements.length,
                          itemBuilder: (context, index) {
                            final settlement = settlements[index];
                            return AnimatedWrapper.staggered(
                              index: index,
                              duration: const Duration(milliseconds: 300),
                              staggerDelay: const Duration(milliseconds: 50),
                              child: _buildSettlementListItem(
                                context,
                                settlement,
                                colorScheme,
                                textTheme,
                              ),
                            );
                          },
                        ),
                      ),
                      _buildSettlementInstructionsCard(colorScheme, textTheme),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.05),
            primaryColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),

          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              badgeText,
              style: textTheme.labelSmall?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSettledMessage(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: colorScheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline,
                size: 48, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 24),
          Text('All settled up!',
              style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600, color: colorScheme.primary)),
          const SizedBox(height: 12),
          Text('There are no settlements needed.',
              style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => setState(() {}), // Refresh state
            icon: Icon(Icons.refresh,
                size: 18, color: colorScheme.onPrimaryContainer),
            label: const Text('Refresh'),
            style: FilledButton.styleFrom(
              backgroundColor:
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
              foregroundColor: colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(
                  horizontal: kPadding, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementInstructionsCard(
      ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: kPadding),
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('How to Settle Up',
                  style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: colorScheme.primary)),
            ]),
            const SizedBox(height: 12),
            _buildInstructionStep(textTheme, colorScheme, '1.',
                'Follow the payment directions above (tap for details)'),
            const SizedBox(height: 4),
            _buildInstructionStep(textTheme, colorScheme, '2.',
                'Mark settlements as complete once paid'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(TextTheme textTheme, ColorScheme colorScheme,
      String number, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(number,
          style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold, color: colorScheme.primary)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant))),
    ]);
  }

  Widget _buildSettlementListItem(
    BuildContext context,
    Settlement settlement,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: widget.outlineBorderSide),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            _showSettlementDetailsDialog(settlement, colorScheme, textTheme),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Left section: From User (fixed width)
              SizedBox(
                width: 110, // Fixed width for the left user
                child: _buildSettlementUser(
                    settlement.from, true, colorScheme, textTheme),
              ),

              // Middle section: Arrow & Amount (expanded to fill available space)
              Expanded(
                child: Center(
                  child: _buildSettlementArrow(
                      settlement.amount, colorScheme, textTheme),
                ),
              ),

              // Right section: To User (fixed width)
              SizedBox(
                width: 110, // Fixed width for the right user
                child: _buildSettlementUser(
                    settlement.to, false, colorScheme, textTheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettlementUser(String userId, bool isDebtor,
      ColorScheme colorScheme, TextTheme textTheme) {
    final color = isDebtor ? colorScheme.error : colorScheme.tertiary;
    final bgColor = color.withValues(alpha: 0.1);
    final fgColor = color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          isDebtor ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        // Conditionally add avatar before/after name based on isDebtor
        if (isDebtor) ...[
          FutureBuilder<Map<String, dynamic>>(
            future: widget.userService.isUser(userId).then((isUser) => isUser
                ? widget.userService.getUserNameAndImage(userId)
                : {'name': userId, 'profileImageUrl': null}),
            builder: (context, snapshot) {
              final userName = snapshot.data?['name'] ?? '?';
              final profileImageUrl = snapshot.data?['profileImageUrl'];
              return UserAvatar(
                userName: userName,
                profileImageUrl: profileImageUrl,
                radius: 16,
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                shadowColor: color.withValues(alpha: 0.1),
                showShadow: true,
              );
            },
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: FutureBuilder<String>(
            future: widget.userService.isUser(userId).then((isUser) =>
                isUser ? widget.userService.getUserName(userId) : userId),
            builder: (context, snapshot) => Text(
              snapshot.data ?? '...',
              style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500, color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
              textAlign: isDebtor ? TextAlign.left : TextAlign.right,
            ),
          ),
        ),
        if (!isDebtor) ...[
          const SizedBox(width: 6),
          FutureBuilder<Map<String, dynamic>>(
            future: widget.userService.isUser(userId).then((isUser) => isUser
                ? widget.userService.getUserNameAndImage(userId)
                : {'name': userId, 'profileImageUrl': null}),
            builder: (context, snapshot) {
              final userName = snapshot.data?['name'] ?? '?';
              final profileImageUrl = snapshot.data?['profileImageUrl'];
              return UserAvatar(
                userName: userName,
                profileImageUrl: profileImageUrl,
                radius: 16,
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                shadowColor: color.withValues(alpha: 0.1),
                showShadow: true,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSettlementArrow(
      double amount, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pays indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.arrow_forward, size: 12, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text('pays',
                style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500, color: colorScheme.primary)),
          ]),
        ),
        const SizedBox(height: 4), // Consistent spacing
        // Amount
        Text(
          '${getCurrencySymbol(widget.settingsService.currency)}${amount.toStringAsFixed(2)}',
          style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700, color: colorScheme.primary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showSettlementDetailsDialog(
    Settlement settlement,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Text(
            'Settlement Details',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'To settle the balance:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<String>>(
                future: Future.wait([
                  widget.userService.isUser(settlement.from).then((isUser) =>
                      isUser
                          ? widget.userService.getUserName(settlement.from)
                          : settlement.from),
                  widget.userService.isUser(settlement.to).then((isUser) =>
                      isUser
                          ? widget.userService.getUserName(settlement.to)
                          : settlement.to),
                ]),
                builder: (context, snapshot) {
                  final fromName = snapshot.data?[0] ?? '...';
                  final toName = snapshot.data?[1] ?? '...';
                  return Column(
                    children: [
                      Text(
                        '$fromName needs to pay $toName',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
              Text(
                '${getCurrencySymbol(widget.settingsService.currency)}${settlement.amount.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Once the payment is made, tap below to mark it as complete.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isProcessing ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      setState(() => isProcessing = true);
                      final scaffoldMessengerState =
                          ScaffoldMessenger.of(context);

                      try {
                        final result =
                            await widget.expenseService.markSettlementAsSettled(
                          widget.group.id,
                          settlement.from,
                          settlement.to,
                          settlement.amount,
                        );

                        if (!mounted) return;
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }

                        if (result != null) {
                          scaffoldMessengerState.showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: colorScheme.onPrimary),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                      child: Text(
                                          'Settlement marked as complete!')),
                                ],
                              ),
                              backgroundColor: colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          widget.onSettlementCompleted();
                        } else {
                          scaffoldMessengerState.showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: colorScheme.onError),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                      child: Text(
                                          'Failed to mark settlement as complete')),
                                ],
                              ),
                              backgroundColor: colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }

                        scaffoldMessengerState.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: colorScheme.onError),
                                const SizedBox(width: 12),
                                Expanded(child: Text('Error: ${e.toString()}')),
                              ],
                            ),
                            backgroundColor: colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => isProcessing = false);
                      }
                    },
              child: isProcessing
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Processing...'),
                      ],
                    )
                  : const Text('Mark as Settled'),
            ),
          ],
        ),
      ),
    );
  }
}

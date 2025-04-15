import 'package:flutter/material.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/widgets/expence_analysis_components/user_avatar.dart';
import 'package:splitwise/features/expense_tracking/models/expense_analysis_models.dart';
import 'package:splitwise/widgets/common/animated_wrapper.dart';
import 'package:splitwise/widgets/expence_analysis_components/future_content_builder.dart';

class BalancesTab extends StatelessWidget {
  final Group group;
  final ExpenseService expenseService;
  final SettingsService settingsService;
  final UserService userService;
  final BorderSide outlineBorderSide;
  final BorderRadius cardBorderRadius;

  const BalancesTab({
    super.key,
    required this.group,
    required this.expenseService,
    required this.settingsService,
    required this.userService,
    required this.outlineBorderSide,
    required this.cardBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: kPadding, bottom: 12),
            child: Text('Member Balances',
                style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.2)),
          ),
          Expanded(
            child: FutureContentBuilder<Map<String, double>>(
              future: expenseService.calculateBalances(group.id),
              loadingMessage: 'Loading balances...',
              emptyDataIcon: Icons.account_balance_wallet_outlined,
              emptyDataMessage: 'No balance data',
              emptyDataDescription: 'Add expenses to see member balances',
              builder: (context, balances) {
                final sortedEntries = balances.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: kPadding),
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    return AnimatedWrapper.staggered(
                      index: index,
                      duration: const Duration(milliseconds: 300),
                      staggerDelay: const Duration(milliseconds: 50),
                      child: _buildBalanceListItem(
                        context,
                        entry,
                        colorScheme,
                        textTheme,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceListItem(
    BuildContext context,
    MapEntry<String, double> entry,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final bool isCredit = entry.value >= 0;
    final Color valueColor =
        isCredit ? colorScheme.tertiary : colorScheme.error;
    final Color bgColor = valueColor.withValues(alpha: 0.1);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: cardBorderRadius, side: outlineBorderSide),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // Show a dialog with more details if needed
          final userName = await userService.getUserName(entry.key);
          if (!context.mounted) return;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Balance Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<String?>(
                    future: userService.getProfileImageUrl(entry.key),
                    builder: (context, imageSnapshot) {
                      return UserAvatar(
                        userName: userName,
                        profileImageUrl: imageSnapshot.data,
                        radius: 30,
                        backgroundColor: bgColor,
                        foregroundColor: valueColor,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCredit ? 'To receive' : 'To pay',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${settingsService.currency}${entry.value.abs().toStringAsFixed(2)}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Left section: Avatar with name (fixed width)
              SizedBox(
                width: 120, // Fixed width for the left section
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<Map<String, dynamic>>(
                      future: userService.getUserNameAndImage(entry.key),
                      builder: (context, snapshot) {
                        final userName = snapshot.data?['name'] ?? '?';
                        final profileImageUrl =
                            snapshot.data?['profileImageUrl'];
                        return UserAvatar(
                          userName: userName,
                          profileImageUrl: profileImageUrl,
                          radius: 16,
                          backgroundColor: bgColor,
                          foregroundColor: valueColor,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: userService.getUserNameAndImage(entry.key),
                        builder: (context, snapshot) => Text(
                          snapshot.data?['name'] ?? '...',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Middle section: Status indicator (expanded to fill available space)
              Expanded(
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCredit
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 12,
                          color: valueColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCredit ? 'Receives' : 'Pays',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: valueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Right section: Amount (fixed width with alignment)
              SizedBox(
                width: 90, // Fixed width for the amount
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${settingsService.currency}${entry.value.abs().toStringAsFixed(2)}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

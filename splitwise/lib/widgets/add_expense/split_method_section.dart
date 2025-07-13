import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/utils/currency_utils.dart';

class SplitMethodSection extends StatelessWidget {
  final Group group;
  final UserService userService;
  final String splitMethod;
  final List<String> splitMethods;
  final Function(String) onSplitMethodChanged;
  final Map<String, bool> participants;
  final Map<String, double> customSplitAmounts;
  final Map<String, double> percentageSplits;
  final Map<String, int> shareSplits;
  final Function(String, double) onCustomSplitChanged;
  final Function(String, double) onPercentageSplitChanged;
  final Function(String, int) onShareSplitChanged;
  final double? totalAmount;

  const SplitMethodSection({
    super.key,
    required this.group,
    required this.userService,
    required this.splitMethod,
    required this.splitMethods,
    required this.onSplitMethodChanged,
    required this.participants,
    required this.customSplitAmounts,
    required this.percentageSplits,
    required this.shareSplits,
    required this.onCustomSplitChanged,
    required this.onPercentageSplitChanged,
    required this.onShareSplitChanged,
    this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
        children: [
          _buildHeader(
            context,
            colorScheme,
            textTheme,
            icon: Icons.call_split_rounded,
            title: 'Split Method',
            subtitle: 'How the expense is divided',
            primaryColor: colorScheme.primary,
            badgeText: 'Method',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSplitMethodSelector(context),
                if (splitMethod != 'Equal') ...[
                  const SizedBox(height: 20),
                  Text(
                    'Split Details',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSplitInputs(context),
                  if (totalAmount != null && totalAmount! > 0) ...[
                    const SizedBox(height: 16),
                    _buildSplitSummary(context),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitMethodSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: splitMethods.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final method = splitMethods[index];
              final isSelected = splitMethod == method;
              return GestureDetector(
                onTap: () => onSplitMethodChanged(method),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 80,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.outline.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getSplitMethodIcon(method),
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        method,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (splitMethod != 'Equal') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getSplitMethodDescription(splitMethod),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSplitInputs(BuildContext context) {
    final allMembers = [...group.memberIds, ...group.invitedEmails];
    final activeParticipants =
        allMembers.where((member) => participants[member] ?? false).toList();

    return Column(
      children: activeParticipants
          .map((member) => _buildParticipantCard(context, member))
          .toList(),
    );
  }

  Widget _buildParticipantCard(BuildContext context, String memberIdentifier) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParticipantHeader(context, memberIdentifier),
          const SizedBox(height: 12),
          _buildInputField(context, memberIdentifier),
        ],
      ),
    );
  }

  Widget _buildParticipantHeader(
      BuildContext context, String memberIdentifier) {
    final isInvited = group.invitedEmails.contains(memberIdentifier);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: isInvited
          ? Future.value(memberIdentifier)
          : userService.getUserName(memberIdentifier),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'Loading...';
        return Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                userName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _getCurrentValueDisplay(memberIdentifier, context),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputField(BuildContext context, String memberIdentifier) {
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    final currencySymbol = getCurrencySymbol(settingsService.currency);
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      initialValue: _getInitialValue(memberIdentifier),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Icon(
          _getInputIcon(),
          size: 20,
          color: colorScheme.primary,
        ),
        prefixText: splitMethod == 'Exact' ? '$currencySymbol ' : null,
        suffixText: splitMethod == 'Percentage'
            ? ' %'
            : splitMethod == 'Shares'
                ? ' shares'
                : null,
        hintText: _getHintText(),
      ),
      onChanged: (value) => _onInputChanged(memberIdentifier, value),
    );
  }

  String _getInitialValue(String memberIdentifier) {
    switch (splitMethod) {
      case 'Exact':
        return customSplitAmounts[memberIdentifier]?.toString() ?? '';
      case 'Percentage':
        return percentageSplits[memberIdentifier]?.toString() ?? '';
      case 'Shares':
        return shareSplits[memberIdentifier]?.toString() ?? '1';
      default:
        return '';
    }
  }

  String _getHintText() {
    switch (splitMethod) {
      case 'Exact':
        return '0.00';
      case 'Percentage':
        return '0';
      case 'Shares':
        return '1';
      default:
        return '';
    }
  }

  void _onInputChanged(String memberIdentifier, String value) {
    switch (splitMethod) {
      case 'Exact':
        onCustomSplitChanged(memberIdentifier, double.tryParse(value) ?? 0);
        break;
      case 'Percentage':
        onPercentageSplitChanged(memberIdentifier, double.tryParse(value) ?? 0);
        break;
      case 'Shares':
        onShareSplitChanged(memberIdentifier, int.tryParse(value) ?? 1);
        break;
    }
  }

  String _getCurrentValueDisplay(
      String memberIdentifier, BuildContext context) {
    if (totalAmount == null || totalAmount! <= 0) return '';
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    final currencySymbol = getCurrencySymbol(settingsService.currency);

    switch (splitMethod) {
      case 'Exact':
        final amount = customSplitAmounts[memberIdentifier] ?? 0;
        return '$currencySymbol${amount.toStringAsFixed(2)}';
      case 'Percentage':
        final percentage = percentageSplits[memberIdentifier] ?? 0;
        final amount = (totalAmount! * percentage) / 100;
        return '$currencySymbol${amount.toStringAsFixed(2)}';
      case 'Shares':
        final totalShares =
            shareSplits.values.where((s) => s > 0).fold(0, (p, c) => p + c);
        if (totalShares == 0) return '${currencySymbol}0.00';
        final userShares = shareSplits[memberIdentifier] ?? 0;
        final amount = (totalAmount! * userShares) / totalShares;
        return '$currencySymbol${amount.toStringAsFixed(2)}';
      default:
        return '';
    }
  }

  IconData _getSplitMethodIcon(String method) {
    switch (method) {
      case 'Equal':
        return Icons.balance_rounded;
      case 'Exact':
        return Icons.money_rounded;
      case 'Percentage':
        return Icons.percent_rounded;
      case 'Shares':
        return Icons.pie_chart_rounded;
      default:
        return Icons.calculate_rounded;
    }
  }

  IconData _getInputIcon() {
    switch (splitMethod) {
      case 'Exact':
        return Icons.attach_money_rounded;
      case 'Percentage':
        return Icons.percent_rounded;
      case 'Shares':
        return Icons.pie_chart_outline_rounded;
      default:
        return Icons.money_rounded;
    }
  }

  String _getSplitMethodDescription(String method) {
    switch (method) {
      case 'Exact':
        return 'Specify the exact amount each person pays.';
      case 'Percentage':
        return 'Split by percentage of the total amount.';
      case 'Shares':
        return 'Split by shares (e.g., 2 shares for one, 1 for another).';
      default:
        return '';
    }
  }

  Widget _buildSplitSummary(BuildContext context) {
    if (totalAmount == null || totalAmount! <= 0) {
      return const SizedBox.shrink();
    }

    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    final currencySymbol = getCurrencySymbol(settingsService.currency);
    final colorScheme = Theme.of(context).colorScheme;
    bool isValid = true;
    String message = '';
    double totalAllocated = 0;

    final activeParticipants = participants.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    switch (splitMethod) {
      case 'Exact':
        totalAllocated = activeParticipants.fold<double>(
          0,
          (sum, uid) => sum + (customSplitAmounts[uid] ?? 0),
        );
        final difference = (totalAmount! - totalAllocated).abs();
        isValid = difference < 0.01;
        message =
            'Total: $currencySymbol${totalAllocated.toStringAsFixed(2)} / ${totalAmount!.toStringAsFixed(2)}';
        break;

      case 'Percentage':
        final totalPercentage = activeParticipants.fold<double>(
          0,
          (sum, uid) => sum + (percentageSplits[uid] ?? 0),
        );
        isValid = (totalPercentage - 100).abs() < 0.01;
        message = 'Total: ${totalPercentage.toStringAsFixed(1)}% / 100%';
        break;

      case 'Shares':
        final totalShares = activeParticipants.fold<int>(
          0,
          (sum, uid) => sum + (shareSplits[uid] ?? 1),
        );
        isValid = totalShares > 0;
        message = 'Total shares: $totalShares';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? colorScheme.primary.withValues(alpha: 0.2)
              : colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.error_outline,
            size: 20,
            color: isValid ? colorScheme.primary : colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isValid ? colorScheme.primary : colorScheme.error,
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
            child: Icon(icon, size: 20, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

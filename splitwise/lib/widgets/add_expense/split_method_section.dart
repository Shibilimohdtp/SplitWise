import 'package:flutter/material.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/widgets/form/section_card.dart';
import 'package:splitwise/widgets/form/section_header.dart';

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
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Split Method',
            icon: Icons.calculate_outlined,
          ),
          const SizedBox(height: 12),
          _buildSplitMethodSelector(context),
          if (splitMethod != 'Equal') ...[
            const SizedBox(height: 20),
            Text(
              'Split Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            _buildSplitInputs(context),
            if (totalAmount != null && totalAmount! > 0) ...[
              const SizedBox(height: 16),
              _buildSplitSummary(context),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSplitMethodSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: splitMethods.map((method) {
              final isSelected = splitMethod == method;
              return GestureDetector(
                onTap: () => onSplitMethodChanged(method),
                child: Container(
                  width: MediaQuery.of(context).size.width / 4.8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getSplitMethodIcon(method),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        method,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (splitMethod != 'Equal') ...[
          const SizedBox(height: 16),
          Text(
            _getSplitMethodDescription(splitMethod),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParticipantHeader(context, memberIdentifier),
          const SizedBox(height: 12),
          _buildInputField(context, memberIdentifier),
          _buildCalculationHelper(context, memberIdentifier),
        ],
      ),
    );
  }

  Widget _buildParticipantHeader(
      BuildContext context, String memberIdentifier) {
    final isInvited = group.invitedEmails.contains(memberIdentifier);
    return FutureBuilder<String>(
      future: isInvited
          ? Future.value(memberIdentifier)
          : userService.getUserName(memberIdentifier),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'Loading...';
        return Row(
          children: [
            // You can add a user avatar here if available
            const Icon(Icons.person_outline, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                userName,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _getCurrentValueDisplay(memberIdentifier),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputField(BuildContext context, String memberIdentifier) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getInputIcon(),
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            initialValue: _getInitialValue(memberIdentifier),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              prefixText: splitMethod == 'Exact' ? '\$ ' : null,
              suffixText: splitMethod == 'Percentage' ? ' %' : null,
              hintText: _getHintText(),
            ),
            onChanged: (value) => _onInputChanged(memberIdentifier, value),
          ),
        ),
        if (_isValid(memberIdentifier))
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildCalculationHelper(
      BuildContext context, String memberIdentifier) {
    final helperText = _getHelperText(memberIdentifier);
    if (helperText.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              helperText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
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

  bool _isValid(String memberIdentifier) {
    // Basic validation, can be expanded
    switch (splitMethod) {
      case 'Exact':
        return (customSplitAmounts[memberIdentifier] ?? 0) > 0;
      case 'Percentage':
        return (percentageSplits[memberIdentifier] ?? 0) > 0;
      case 'Shares':
        return (shareSplits[memberIdentifier] ?? 0) > 0;
      default:
        return false;
    }
  }

  String _getCurrentValueDisplay(String memberIdentifier) {
    if (totalAmount == null || totalAmount! <= 0) return '';

    switch (splitMethod) {
      case 'Exact':
        final amount = customSplitAmounts[memberIdentifier] ?? 0;
        return '\$${amount.toStringAsFixed(2)}';
      case 'Percentage':
        final percentage = percentageSplits[memberIdentifier] ?? 0;
        final amount = (totalAmount! * percentage) / 100;
        return '\$${amount.toStringAsFixed(2)}';
      case 'Shares':
        final totalShares =
            shareSplits.values.where((s) => s > 0).fold(0, (p, c) => p + c);
        if (totalShares == 0) return '\$0.00';
        final userShares = shareSplits[memberIdentifier] ?? 0;
        final amount = (totalAmount! * userShares) / totalShares;
        return '\$${amount.toStringAsFixed(2)}';
      default:
        return '';
    }
  }

  String _getHelperText(String memberIdentifier) {
    if (totalAmount == null || totalAmount! <= 0) {
      return 'Enter total amount to see split calculations.';
    }

    switch (splitMethod) {
      case 'Exact':
        final totalAllocated =
            customSplitAmounts.values.fold(0.0, (p, c) => p + c);
        final remaining = totalAmount! - totalAllocated;
        return 'Remaining: \$${remaining.toStringAsFixed(2)}';
      case 'Percentage':
        final totalPercentage =
            percentageSplits.values.fold(0.0, (p, c) => p + c);
        final remaining = 100 - totalPercentage;
        return 'Remaining: ${remaining.toStringAsFixed(1)}%';
      case 'Shares':
        final totalShares =
            shareSplits.values.where((s) => s > 0).fold(0, (p, c) => p + c);
        return 'Total shares: $totalShares';
      default:
        return '';
    }
  }

  IconData _getSplitMethodIcon(String method) {
    switch (method) {
      case 'Equal':
        return Icons.drag_handle;
      case 'Exact':
        return Icons.attach_money;
      case 'Percentage':
        return Icons.percent;
      case 'Shares':
        return Icons.pie_chart;
      default:
        return Icons.calculate_outlined;
    }
  }

  IconData _getInputIcon() {
    switch (splitMethod) {
      case 'Exact':
        return Icons.money;
      case 'Percentage':
        return Icons.percent_outlined;
      case 'Shares':
        return Icons.pie_chart_outline;
      default:
        return Icons.money;
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
            'Total: \$${totalAllocated.toStringAsFixed(2)} of \$${totalAmount!.toStringAsFixed(2)}';
        break;

      case 'Percentage':
        final totalPercentage = activeParticipants.fold<double>(
          0,
          (sum, uid) => sum + (percentageSplits[uid] ?? 0),
        );
        isValid = (totalPercentage - 100).abs() < 0.01;
        message = 'Total: ${totalPercentage.toStringAsFixed(1)}% of 100%';
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
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: isValid
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isValid
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

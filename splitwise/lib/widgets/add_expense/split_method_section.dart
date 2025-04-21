import 'package:flutter/material.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/utils/app_color.dart';
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

  // Get the total amount from the parent widget
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
            const SizedBox(height: 12),
            Text(
              'Split Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
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
    switch (splitMethod) {
      case 'Exact':
        return _buildExactSplitInputs(context);
      case 'Percentage':
        return _buildPercentageSplitInputs(context);
      case 'Shares':
        return _buildShareSplitInputs(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildExactSplitInputs(BuildContext context) {
    return Column(
      children: group.members.map((memberId) {
        if (participants[memberId] ?? false) {
          return FutureBuilder<String>(
            future: userService.getUserName(memberId),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Loading...';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue:
                            customSplitAmounts[memberId]?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                          prefixText: '\$',
                        ),
                        onChanged: (value) {
                          onCustomSplitChanged(
                              memberId, double.tryParse(value) ?? 0);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildPercentageSplitInputs(BuildContext context) {
    return Column(
      children: group.members.map((memberId) {
        if (participants[memberId] ?? false) {
          return FutureBuilder<String>(
            future: userService.getUserName(memberId),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Loading...';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue:
                            percentageSplits[memberId]?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                          suffixText: '%',
                        ),
                        onChanged: (value) {
                          onPercentageSplitChanged(
                              memberId, double.tryParse(value) ?? 0);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildShareSplitInputs(BuildContext context) {
    return Column(
      children: group.members.map((memberId) {
        if (participants[memberId] ?? false) {
          return FutureBuilder<String>(
            future: userService.getUserName(memberId),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Loading...';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: shareSplits[memberId]?.toString() ?? '1',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                          hintText: '1',
                        ),
                        onChanged: (value) {
                          onShareSplitChanged(
                              memberId, int.tryParse(value) ?? 1);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
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

  String _getSplitMethodDescription(String method) {
    switch (method) {
      case 'Exact':
        return 'Specify the exact amount each person pays';
      case 'Percentage':
        return 'Split by percentage of the total';
      case 'Shares':
        return 'Split by shares (e.g., 1 share each or custom ratio)';
      default:
        return '';
    }
  }

  Widget _buildSplitSummary(BuildContext context) {
    if (totalAmount == null || totalAmount! <= 0) {
      return const SizedBox.shrink();
    }

    double totalAllocated = 0;
    double totalPercentage = 0;
    int totalShares = 0;

    // Calculate totals based on split method
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
        break;

      case 'Percentage':
        totalPercentage = activeParticipants.fold<double>(
          0,
          (sum, uid) => sum + (percentageSplits[uid] ?? 0),
        );
        break;

      case 'Shares':
        totalShares = activeParticipants.fold<int>(
          0,
          (sum, uid) => sum + (shareSplits[uid] ?? 1),
        );
        break;
    }

    // Build the summary widget based on split method
    bool isValid = true;
    String message = '';

    switch (splitMethod) {
      case 'Exact':
        final difference = (totalAmount! - totalAllocated).abs();
        isValid = difference < 0.01; // Allow small rounding errors

        if (totalAllocated == 0) {
          message = 'Please specify amounts';
        } else if (!isValid) {
          message = totalAllocated > totalAmount!
              ? 'Total exceeds expense amount by ${(totalAllocated - totalAmount!).toStringAsFixed(2)}'
              : 'Total is short by ${(totalAmount! - totalAllocated).toStringAsFixed(2)}';
        } else {
          message = 'Total: ${totalAmount!.toStringAsFixed(2)}';
        }
        break;

      case 'Percentage':
        isValid =
            (totalPercentage - 100).abs() < 0.01; // Allow small rounding errors

        if (totalPercentage == 0) {
          message = 'Please specify percentages';
        } else if (!isValid) {
          message = totalPercentage > 100
              ? 'Total exceeds 100% by ${(totalPercentage - 100).toStringAsFixed(1)}%'
              : 'Total is short by ${(100 - totalPercentage).toStringAsFixed(1)}%';
        } else {
          message = 'Total: 100%';
        }
        break;

      case 'Shares':
        if (totalShares == 0) {
          isValid = false;
          message = 'Please specify shares';
        } else {
          message = 'Total: $totalShares shares';
          isValid = true;
        }
        break;

      default:
        return const SizedBox.shrink();
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

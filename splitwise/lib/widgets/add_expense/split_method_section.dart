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
                              .withValues(alpha: 0.1),
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
}

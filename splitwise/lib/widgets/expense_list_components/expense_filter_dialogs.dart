import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:splitwise/utils/app_color.dart';

class ExpenseFilterDialogs {
  static Future<DateTimeRange?> showDateRangeFilterDialog(
      BuildContext context, DateTimeRange? currentRange) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<DateTimeRange?>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.date_range_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select Time Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickSelectChip(
                    context: context,
                    label: 'Last 7 days',
                    onTap: () => _setQuickDateRange(context, 7),
                  ),
                  _buildQuickSelectChip(
                    context: context,
                    label: 'Last 30 days',
                    onTap: () => _setQuickDateRange(context, 30),
                  ),
                  _buildQuickSelectChip(
                    context: context,
                    label: 'Last 3 months',
                    onTap: () => _setQuickDateRange(context, 90),
                  ),
                  _buildQuickSelectChip(
                    context: context,
                    label: 'Last 6 months',
                    onTap: () => _setQuickDateRange(context, 180),
                  ),
                  _buildQuickSelectChip(
                    context: context,
                    label: 'This year',
                    onTap: () {
                      final now = DateTime.now();
                      final startOfYear = DateTime(now.year, 1, 1);
                      Navigator.pop(
                          context, DateTimeRange(start: startOfYear, end: now));
                    },
                  ),
                  _buildQuickSelectChip(
                    context: context,
                    label: 'All time',
                    onTap: () {
                      Navigator.pop(context, null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDateRange: currentRange ??
                        DateTimeRange(
                          start:
                              DateTime.now().subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        ),
                  );
                  if (picked != null && context.mounted) {
                    Navigator.pop(context, picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Custom Range',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildQuickSelectChip({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static void _setQuickDateRange(BuildContext context, int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    Navigator.pop(context, DateTimeRange(start: start, end: now));
  }

  static String getDateRangeDisplayText(DateTimeRange range) {
    String dateText;
    final now = DateTime.now();
    final start = range.start;
    final end = range.end;

    final difference = end.difference(start).inDays;

    if (difference == 6) {
      dateText = 'Last 7 days';
    } else if (difference == 29) {
      dateText = 'Last 30 days';
    } else if (difference == 89) {
      dateText = 'Last 3 months';
    } else if (difference == 179) {
      dateText = 'Last 6 months';
    } else if (start.year == end.year &&
        start.month == 1 &&
        start.day == 1 &&
        end.day == now.day &&
        end.month == now.month) {
      dateText = 'This year';
    } else {
      final startFormatted = DateFormat('MMM d').format(start);
      final endFormatted = DateFormat('MMM d').format(end);
      dateText = '$startFormatted - $endFormatted';
    }

    return dateText;
  }

  static Future<String?> showMemberSelectionDialog(
      BuildContext context, List<dynamic> members) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(
            'Select Member',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, null);
              },
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'All Members',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ...members.map((member) {
              // Handle both User objects and map-like structures
              String memberId = '';
              String memberName = 'Unknown';

              if (member is Map) {
                memberId = member['uid'] ?? '';
                memberName = member['name'] ?? 'Unknown';
              } else {
                // Assuming it's a User object with uid and name properties
                try {
                  memberId = member.uid;
                  memberName = member.name;
                } catch (e) {
                  // Silent error - fallback to default values
                  // In a production app, use a proper logging framework
                }
              }

              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, memberId);
                },
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    // Avatar circle with first letter of name
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        memberName.isNotEmpty
                            ? memberName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Member name
                    Expanded(
                      child: Text(
                        memberName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

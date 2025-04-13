import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:splitwise/utils/app_color.dart';

class ExpenseFilterDialogs {
  static Future<DateTimeRange?> showDateRangeFilterDialog(BuildContext context, DateTimeRange? currentRange) {
    return showDialog<DateTimeRange?>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Time Period',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
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
                      Navigator.pop(context, DateTimeRange(start: startOfYear, end: now));
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
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final ThemeData theme = Theme.of(context);
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
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: theme.copyWith(
                          colorScheme: theme.colorScheme.copyWith(
                            primary: AppColors.primaryMain,
                            onPrimary: Colors.white,
                            surface: AppColors.surfaceLight,
                            onSurface: AppColors.textMain,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && context.mounted) {
                    Navigator.pop(context, picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: AppColors.primaryMain),
                      SizedBox(width: 12),
                      Text(
                        'Custom Range',
                        style: TextStyle(
                          color: AppColors.primaryMain,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppColors.textLight),
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
              child: Text(
                'All Members',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...members.map((member) => SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, member['uid']);
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    member['name'] ?? 'Unknown',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}

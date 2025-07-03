import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/widgets/feedback/status_snackbar.dart';

class ExpenseConfirmationBottomSheet extends StatefulWidget {
  final Expense expense;
  final Group group;
  final ExpenseService expenseService;
  final UserService userService;
  final SettingsService settingsService;
  final VoidCallback onSuccess;

  const ExpenseConfirmationBottomSheet({
    super.key,
    required this.expense,
    required this.group,
    required this.expenseService,
    required this.userService,
    required this.settingsService,
    required this.onSuccess,
  });

  static Future<bool> show({
    required BuildContext context,
    required Expense expense,
    required Group group,
    required ExpenseService expenseService,
    required UserService userService,
    required SettingsService settingsService,
    required VoidCallback onSuccess,
  }) async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ExpenseConfirmationBottomSheet(
            expense: expense,
            group: group,
            expenseService: expenseService,
            userService: userService,
            settingsService: settingsService,
            onSuccess: onSuccess,
          ),
        ) ??
        false;
  }

  @override
  State<ExpenseConfirmationBottomSheet> createState() =>
      _ExpenseConfirmationBottomSheetState();
}

class _ExpenseConfirmationBottomSheetState
    extends State<ExpenseConfirmationBottomSheet> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              _buildBottomSheetHandle(context),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      _buildExpenseInfo(context),
                      const SizedBox(height: 24),
                      _buildSplitDetails(context),
                      if (widget.expense.comment?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 24),
                        _buildCommentSection(context),
                      ],
                      const SizedBox(height: 32),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomSheetHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Confirm Expense',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(widget.expense.category)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.expense.category,
                style: TextStyle(
                  color: _getCategoryColor(widget.expense.category),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.expense.currency}${widget.expense.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.expense.description,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildExpenseInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context: context,
            icon: Icons.group_outlined,
            label: 'Group',
            value: widget.group.name,
          ),
          Divider(
            height: 20,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          _buildInfoRow(
            context: context,
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: DateFormat('MMMM d, yyyy').format(widget.expense.date),
          ),
          Divider(
            height: 20,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          _buildInfoRow(
            context: context,
            icon: Icons.calculate_outlined,
            label: 'Split Method',
            value: widget.expense.splitMethod,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.comment_outlined,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Comment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.expense.comment!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Split Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: FutureBuilder<List<Widget>>(
            future: _buildSplitDetailsList(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }
              return Column(children: snapshot.data ?? []);
            },
          ),
        ),
      ],
    );
  }

  Future<List<Widget>> _buildSplitDetailsList(BuildContext context) async {
    // Capture theme values before async operations
    final outlineColor =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    List<Widget> widgets = [];
    final entries = widget.expense.splitDetails.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isLastItem = i == entries.length - 1;
      final isInvited = widget.group.invitedEmails.contains(entry.key);
      final userName = isInvited
          ? entry.key
          : await widget.userService.getUserName(entry.key);

      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: isLastItem
                ? null
                : Border(
                    bottom: BorderSide(
                      color: outlineColor,
                      width: 1,
                    ),
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userName,
                style: textStyle?.copyWith(
                  color: onSurfaceColor,
                ),
              ),
              Text(
                '${widget.settingsService.currency}${entry.value.toStringAsFixed(2)}',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                _isSubmitting ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontSize: 14),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submitExpense,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontSize: 14),
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Future<void> _submitExpense() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.expenseService.addExpense(widget.expense);

      if (mounted) {
        Navigator.pop(context, true);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, false);
        StatusSnackbar.showError(
          context,
          message: 'Failed to add expense',
          details: 'Please try again.',
        );
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFF4CAF50);
      case 'transport':
        return const Color(0xFF2196F3);
      case 'entertainment':
        return const Color(0xFF9C27B0);
      case 'utilities':
        return const Color(0xFFFF9800);
      case 'rent':
        return const Color(0xFF795548);
      default:
        return const Color(0xFF607D8B);
    }
  }
}

// Using the ColorExtension from app_color.dart

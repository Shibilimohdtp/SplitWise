import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/utils/currency_utils.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
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
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'Expense Info',
                      child: _buildExpenseInfo(context),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      icon: Icons.people_alt_rounded,
                      title: 'Split Details',
                      child: _buildSplitDetails(context),
                    ),
                    if (widget.expense.comment?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      _buildSection(
                        context,
                        icon: Icons.comment_rounded,
                        title: 'Comment',
                        child: _buildCommentSection(context),
                      ),
                    ],
                    const SizedBox(height: 32),
                    _buildActionButtons(context),
                  ],
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = _getCategoryColor(widget.expense.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confirm Expense',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.expense.category,
                style: textTheme.labelSmall?.copyWith(
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.expense.description,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.primary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Total Amount',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                '${getCurrencySymbol(widget.expense.currency)}${widget.expense.amount.toStringAsFixed(2)}',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context,
      {required IconData icon, required String title, required Widget child}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              title,
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildExpenseInfo(BuildContext context) {
    return Column(
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.group_rounded,
          label: 'Group',
          value: widget.group.name,
        ),
        const Divider(height: 16),
        _buildInfoRow(
          context: context,
          icon: Icons.calendar_today_rounded,
          label: 'Date',
          value: DateFormat('MMMM d, yyyy').format(widget.expense.date),
        ),
        const Divider(height: 16),
        _buildInfoRow(
          context: context,
          icon: Icons.call_split_rounded,
          label: 'Split Method',
          value: widget.expense.splitMethod,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Text(label, style: textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection(BuildContext context) {
    return Text(
      widget.expense.comment!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
    );
  }

  Widget _buildSplitDetails(BuildContext context) {
    return FutureBuilder<List<Widget>>(
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
    );
  }

  Future<List<Widget>> _buildSplitDetailsList(BuildContext context) async {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
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
                  style: textTheme.bodyMedium,
                ),
              ),
              Text(
                '${getCurrencySymbol(widget.settingsService.currency)}${entry.value.toStringAsFixed(2)}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
      if (!isLastItem) {
        widgets.add(const Divider(height: 1));
      }
    }
    return widgets;
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                _isSubmitting ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side:
                  BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submitExpense,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.onPrimary,
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
        return Colors.green;
      case 'transport':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'utilities':
        return Colors.orange;
      case 'rent':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

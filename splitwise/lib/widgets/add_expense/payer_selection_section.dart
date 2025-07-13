import 'package:flutter/material.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/models/user.dart' as models;
import 'package:splitwise/services/user_service.dart';

class PayerSelectionSection extends StatefulWidget {
  final Group group;
  final UserService userService;
  final String? selectedPayerId;
  final ValueChanged<String?> onPayerSelected;

  const PayerSelectionSection({
    super.key,
    required this.group,
    required this.userService,
    required this.selectedPayerId,
    required this.onPayerSelected,
  });

  @override
  State<PayerSelectionSection> createState() => _PayerSelectionSectionState();
}

class _PayerSelectionSectionState extends State<PayerSelectionSection> {
  Future<List<models.User>>? _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = widget.userService.getGroupMembers(widget.group.memberIds);
  }

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
            icon: Icons.account_balance_wallet_rounded,
            title: 'Paid By',
            subtitle: 'Select who paid for this expense',
            primaryColor: colorScheme.secondary,
            badgeText: 'Payer',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPayerSelector(context),
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

  Widget _buildPayerSelector(BuildContext context) {
    return FutureBuilder<List<models.User>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }
        if (snapshot.hasError) {
          return _buildErrorState(context);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context);
        }

        final users = snapshot.data!;
        final invitedEmails = widget.group.invitedEmails;
        final allPayers = [
          ...users,
          ...invitedEmails.map((email) => models.User(
              uid: email, name: email, username: email, email: email))
        ];

        return DropdownButtonFormField<String>(
          value: widget.selectedPayerId,
          onChanged: widget.onPayerSelected,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.secondary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          items: allPayers.map((user) {
            return DropdownMenuItem<String>(
              value: user.uid,
              child: Text(
                user.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }).toList(),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(BuildContext context) {
    return const Center(child: Text('Error loading members'));
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(child: Text('No members in this group'));
  }
}

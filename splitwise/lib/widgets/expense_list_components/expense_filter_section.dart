import 'package:flutter/material.dart';

class ExpenseFilterSection extends StatelessWidget {
  final String? selectedCategory;
  final DateTimeRange? selectedDateRange;
  final String? selectedMemberId;
  final Function(String?) onCategoryChanged;
  final VoidCallback onSelectDateRange;
  final VoidCallback onSelectMember;
  final VoidCallback onClearFilters;

  const ExpenseFilterSection({
    super.key,
    required this.selectedCategory,
    required this.selectedDateRange,
    required this.selectedMemberId,
    required this.onCategoryChanged,
    required this.onSelectDateRange,
    required this.onSelectMember,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFilters = selectedCategory != null ||
        selectedDateRange != null ||
        selectedMemberId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryDropdown(context),
          ),
          const SizedBox(width: 6),
          _buildFilterButton(
            context: context,
            icon: Icons.date_range_rounded,
            label: selectedDateRange != null ? 'Date ✓' : 'Date',
            onTap: onSelectDateRange,
          ),
          const SizedBox(width: 6),
          _buildFilterButton(
            context: context,
            icon: Icons.person_rounded,
            label: selectedMemberId != null ? 'Member ✓' : 'Member',
            onTap: onSelectMember,
          ),
          if (hasFilters) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onClearFilters,
              icon: Icon(
                Icons.clear_all_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Clear all filters',
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: selectedCategory != null
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selectedCategory != null
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Category',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          isDense: true,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: selectedCategory != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 16,
          ),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
          onChanged: onCategoryChanged,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.clear_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'All Categories',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
            ..._buildCategoryItems(context),
          ],
          dropdownColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          menuMaxHeight: 300,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildCategoryItems(BuildContext context) {
    final categories = [
      'Food',
      'Transport',
      'Entertainment',
      'Utilities',
      'Rent',
      'Other'
    ];

    return categories.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(value),
              size: 14,
              color: _getCategoryColor(value),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFilterButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isActive = label.contains('✓');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.power;
      case 'rent':
        return Icons.home;
      default:
        return Icons.attach_money;
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

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (selectedCategory != null ||
                  selectedDateRange != null ||
                  selectedMemberId != null)
                TextButton(
                  onPressed: onClearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  child: const Text('Clear All'),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildCategoryDropdown(context),
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                context: context,
                icon: Icons.date_range_rounded,
                label: selectedDateRange != null ? 'Date ✓' : 'Date',
                onTap: onSelectDateRange,
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                context: context,
                icon: Icons.person_rounded,
                label: selectedMemberId != null ? 'Member ✓' : 'Member',
                onTap: onSelectMember,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selectedCategory != null
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
            : Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedCategory != null
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          hint: Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Category',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: selectedCategory != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            size: 18,
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onCategoryChanged,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Row(
                children: [
                  Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'All Categories',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            ..._buildCategoryItems(context),
          ],
          dropdownColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
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
          children: [
            Icon(
              _getCategoryIcon(value),
              size: 14,
              color: _getCategoryColor(value),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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

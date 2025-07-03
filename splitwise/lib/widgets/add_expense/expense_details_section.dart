import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/widgets/form/section_card.dart';
import 'package:splitwise/widgets/form/section_header.dart';

class ExpenseDetailsSection extends StatefulWidget {
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final List<String> categories;

  const ExpenseDetailsSection({
    super.key,
    required this.descriptionController,
    required this.amountController,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
  });

  @override
  State<ExpenseDetailsSection> createState() => _ExpenseDetailsSectionState();
}

class _ExpenseDetailsSectionState extends State<ExpenseDetailsSection> {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Expense Details',
            icon: Icons.receipt_outlined,
          ),
          const SizedBox(height: 12),
          _buildDescriptionField(),
          const SizedBox(height: 16),
          _buildAmountField(),
          const SizedBox(height: 16),
          _buildCategorySelector(),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: widget.descriptionController,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.05),
        labelText: 'Description',
        hintText: 'What was this expense for?',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) =>
          value!.isEmpty ? 'Please enter a description' : null,
    );
  }

  Widget _buildAmountField() {
    final currency = context.read<SettingsService>().currency;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currency,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: widget.amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    isDense: true,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter an amount' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              final isSelected = widget.selectedCategory == category;

              return GestureDetector(
                onTap: () => widget.onCategorySelected(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getCategoryColor(category).withValues(alpha: 0.2)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _getCategoryColor(category)
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getCategoryColor(category)
                                  .withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: isSelected
                              ? _getCategoryColor(category)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? _getCategoryColor(category)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
      case 'uncategorized':
        return Icons.category_outlined;
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
      case 'uncategorized':
        return Theme.of(context).colorScheme.primary;
      default:
        return const Color(0xFF607D8B);
    }
  }
}

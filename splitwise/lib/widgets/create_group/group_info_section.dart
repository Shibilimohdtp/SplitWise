import 'package:flutter/material.dart';
import 'package:splitwise/widgets/form/section_card.dart';
import 'package:splitwise/widgets/form/section_header.dart';

class GroupInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String? Function(String?)? nameValidator;
  final String? Function(String?)? descriptionValidator;

  const GroupInfoSection({
    super.key,
    required this.nameController,
    required this.descriptionController,
    this.nameValidator,
    this.descriptionValidator,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Group Information',
            icon: Icons.group_outlined,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            context: context,
            controller: nameController,
            label: 'Group Name',
            hint: 'Enter a descriptive name for your group',
            icon: Icons.group_outlined,
            validator: nameValidator,
            helperText:
                'Choose a name that clearly identifies your group purpose',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context: context,
            controller: descriptionController,
            label: 'Description',
            hint: 'Describe what this group is for',
            icon: Icons.description_outlined,
            maxLines: 3,
            validator: descriptionValidator,
            helperText:
                'Add details about the group purpose, members, or any other relevant information',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    void Function(String)? onSubmitted,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 18),
            filled: true,
            fillColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            helperText: helperText,
            helperStyle: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.7),
              letterSpacing: 0.2,
            ),
            errorStyle: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 0.1,
          ),
          maxLines: maxLines,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          keyboardType: keyboardType,
          cursorColor: Theme.of(context).colorScheme.primary,
          cursorRadius: const Radius.circular(2),
        ),
      ],
    );
  }
}

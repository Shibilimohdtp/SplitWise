import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextEditingController? controller;
  final bool? readOnly;
  final Color? fillColor;
  final Function(String)? onChanged;
  final String? suffixText;

  const CustomTextField({
    Key? key,
    required this.labelText,
    this.onSaved,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines,
    this.controller,
    this.readOnly,
    this.fillColor,
    this.onChanged,
    this.suffixText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: fillColor != null,
        fillColor: fillColor,
        suffixText: suffixText,
      ),
      obscureText: obscureText,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      controller: controller,
      readOnly: readOnly ?? false,
    );
  }
}

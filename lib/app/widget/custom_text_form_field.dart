import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    required this.controller,
    required this.hintText,
    required this.labelText,
    required this.prefixIcon,
    super.key,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onVisibilityToggle,
    this.action,
    this.showVisibilityIcon = false,
  });
  final TextEditingController controller;
  final TextInputAction? action;
  final String hintText;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final VoidCallback? onVisibilityToggle; // For password visibility
  final bool showVisibilityIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: action,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        filled: true,
        fillColor: colorScheme.surface,
        prefixIcon: Icon(
          prefixIcon,
          color: colorScheme.primary,
        ),
        suffixIcon: showVisibilityIcon && onVisibilityToggle != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: colorScheme.primary,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        border: CustomOutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: CustomOutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: CustomOutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      validator: validator,
    );
  }
}

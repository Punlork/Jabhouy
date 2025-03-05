import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';

class CustomTextFormField extends StatefulWidget {
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
    this.showClearButton = false,
    this.decoration,
    this.focusNode,
    this.floatingLabelBehavior,
    this.useCustomBorder = true,
  });

  final TextEditingController controller;
  final TextInputAction? action;
  final String hintText;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final VoidCallback? onVisibilityToggle;
  final bool showVisibilityIcon;
  final bool showClearButton;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final bool useCustomBorder; // Controls whether to use CustomOutlineInputBorder

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(() {
      setState(() {
        _hasText = widget.controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _clearText() {
    widget.controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Define the custom border (used only if useCustomBorder is true)
    final customBorder = widget.useCustomBorder
        ? CustomOutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          )
        : null;

    // Base decoration with conditional border
    final baseDecoration = InputDecoration(
      hintText: widget.hintText,
      labelText: widget.labelText,
      filled: true,
      fillColor: colorScheme.surface,
      prefixIcon: Icon(
        widget.prefixIcon,
        color: colorScheme.primary,
      ),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showClearButton && _hasText)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: colorScheme.onSurface.withValues(alpha: .6),
              ),
              onPressed: _clearText,
            ),
          if (widget.showVisibilityIcon && widget.onVisibilityToggle != null)
            IconButton(
              icon: Icon(
                widget.obscureText ? Icons.visibility_off : Icons.visibility,
                color: colorScheme.primary,
              ),
              onPressed: widget.onVisibilityToggle,
            ),
        ],
      ),
      border: customBorder,
      enabledBorder: customBorder,
      focusedBorder: customBorder,
      labelStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: .6),
      ),
      floatingLabelBehavior: widget.floatingLabelBehavior,
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );

    // Merge with external decoration if provided
    final mergedDecoration = widget.decoration != null
        ? baseDecoration.copyWith(
            contentPadding: widget.decoration!.contentPadding,
            border: widget.decoration!.border,
            enabledBorder: widget.decoration!.enabledBorder,
            focusedBorder: widget.decoration!.focusedBorder,
            filled: widget.decoration!.filled,
            fillColor: widget.decoration!.fillColor,
            hintStyle: widget.decoration!.hintStyle,

            // Add other properties as needed
          )
        : baseDecoration;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      textInputAction: widget.action,
      focusNode: _focusNode,
      decoration: mergedDecoration,
      validator: widget.validator,
    );
  }
}

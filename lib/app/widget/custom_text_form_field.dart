import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    required this.controller,
    required this.hintText,
    required this.labelText,
    this.prefixIcon,
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
    this.onChanged,
    this.useCustomBorder = true,
    this.maxLines,
  });

  final TextEditingController controller;
  final TextInputAction? action;
  final String hintText;
  final String labelText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;
  final VoidCallback? onVisibilityToggle;
  final bool showVisibilityIcon;
  final bool showClearButton;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final bool useCustomBorder;
  final int? maxLines;

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
    widget.onChanged?.call('');
    _focusNode.unfocus();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final customBorder = widget.useCustomBorder
        ? CustomOutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          )
        : const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          );

    final baseDecoration = InputDecoration(
      hintText: widget.hintText,
      labelText: widget.labelText,
      filled: true,
      fillColor: colorScheme.surface,
      prefixIcon: widget.prefixIcon != null
          ? Icon(
              widget.prefixIcon,
              color: colorScheme.primary,
            )
          : null,
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
      disabledBorder: customBorder,
      labelStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: .6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      floatingLabelBehavior: widget.floatingLabelBehavior,
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );

    final mergedDecoration = widget.decoration != null
        ? baseDecoration.copyWith(
            contentPadding: widget.decoration!.contentPadding,
            border: widget.decoration!.border,
            enabledBorder: widget.decoration!.enabledBorder,
            focusedBorder: widget.decoration!.focusedBorder,
            focusedErrorBorder: widget.decoration!.focusedErrorBorder,
            errorBorder: widget.decoration!.errorBorder,
            filled: widget.decoration!.filled,
            fillColor: widget.decoration!.fillColor,
            hintStyle: widget.decoration!.hintStyle,
            suffixText: widget.decoration!.suffixText,
            suffixStyle: widget.decoration!.suffixStyle,

            //! Add other properties as needed
          )
        : baseDecoration;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      onTapOutside: (event) {
        if (!_focusNode.hasFocus) return;
        _focusNode.unfocus();
      },
      textInputAction: widget.action,
      focusNode: _focusNode,
      decoration: mergedDecoration,
      validator: widget.validator,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
    );
  }
}

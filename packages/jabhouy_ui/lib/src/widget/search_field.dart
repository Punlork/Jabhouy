import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// Muted search box with a search icon and an optional trailing widget (mic).
class SearchField extends StatelessWidget {
  const SearchField({
    required this.hintText,
    this.controller,
    this.onChanged,
    this.trailing,
    super.key,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusInput),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: AppSizes.inputHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTextTheme.body.copyWith(color: t.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextTheme.body.copyWith(color: t.placeholder),
          prefixIcon: Icon(Icons.search_rounded, color: t.textMuted),
          suffixIcon: trailing,
          filled: true,
          fillColor: t.surfaceMuted,
          contentPadding: EdgeInsets.zero,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}

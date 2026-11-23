import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// The extended "add" button: above the bottom nav on a phone, floating
/// bottom-right on a tablet. A null [onPressed] shows it disabled.
class AppAddButton extends StatelessWidget {
  const AppAddButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: t.textPrimary,
      foregroundColor: t.onPrimary,
      shape: const StadiumBorder(),
      icon: const Icon(Icons.add_rounded),
      label: Text(label, style: AppTextTheme.label),
    );
  }
}

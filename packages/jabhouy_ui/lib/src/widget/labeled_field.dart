import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// A label above any input (never a placeholder-only label), with an
/// optional `(មិនចាំបាច់)` suffix and a hint below.
class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    required this.child,
    this.optional = false,
    this.hint,
    super.key,
  });

  final String label;

  /// The input: a `TextFormField`, a money input, a picker button.
  final Widget child;
  final bool optional;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (optional)
                TextSpan(
                  text: ' ${context.l10n.optional}',
                  style: AppTextTheme.hint.copyWith(color: t.textMuted),
                ),
            ],
          ),
          style: AppTextTheme.label.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: AppSizes.fieldGap),
        child,
        if (hint != null) ...[
          const SizedBox(height: AppSizes.fieldGap),
          Text(hint!, style: AppTextTheme.hint.copyWith(color: t.textMuted)),
        ],
      ],
    );
  }
}

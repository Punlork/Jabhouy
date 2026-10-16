import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// `មិនទាន់សង` in warning colors or `សងរួច` in success colors.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.paid, super.key});

  final bool paid;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg) = paid
        ? (t.successBg, t.successText)
        : (t.warningBg, t.warningText);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
      ),
      child: Text(
        paid ? context.l10n.creditPaid : context.l10n.creditUnpaid,
        style: AppTextTheme.hint.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// `− n +`, dark once n is above 0. Never goes below 0.
class QtyStepper extends StatelessWidget {
  const QtyStepper({required this.value, required this.onChanged, super.key});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final active = value > 0;
    final fg = active ? t.onPrimary : t.textPrimary;
    return Container(
      decoration: BoxDecoration(
        color: active ? t.textPrimary : t.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSizes.radiusChip + 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            color: fg,
            onTap: active ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextTheme.label.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            color: fg,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: color,
      disabledColor: color.withValues(alpha: 0.35),
      constraints: const BoxConstraints.tightFor(
        width: AppSizes.minTapTarget,
        height: AppSizes.minTapTarget,
      ),
      padding: EdgeInsets.zero,
    );
  }
}

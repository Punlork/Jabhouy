import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// Two buttons side by side, each opening its own picker. The screen
/// formats the text (see the Khmer date text issue); an empty time shows
/// `បន្ថែមម៉ោង` in grey.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    required this.date,
    required this.dateText,
    required this.onDateChanged,
    required this.onTimeChanged,
    this.time,
    this.timeText,
    super.key,
  });

  final DateTime date;
  final String dateText;
  final TimeOfDay? time;
  final String? timeText;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDateChanged(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now(),
    );
    if (picked != null) onTimeChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Expanded(
          child: _PickerButton(
            icon: Icons.calendar_today_rounded,
            text: dateText,
            color: t.textPrimary,
            onTap: () => _pickDate(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PickerButton(
            icon: Icons.schedule_rounded,
            text: timeText ?? context.l10n.timeAdd,
            color: timeText == null ? t.textMuted : t.textPrimary,
            onTap: () => _pickTime(context),
          ),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        side: BorderSide(color: t.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        child: SizedBox(
          height: AppSizes.inputHeight,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 20, color: t.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTheme.body.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

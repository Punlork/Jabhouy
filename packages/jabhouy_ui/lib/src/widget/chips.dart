import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// One chip in a [FilterChips] row.
class FilterChipItem {
  const FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.warningCount,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Non-null makes this the amber warning chip with a count badge;
  /// 0 hides it.
  final int? warningCount;
}

/// Horizontally scrolling filter row: active chips dark, others muted.
class FilterChips extends StatelessWidget {
  const FilterChips({required this.items, super.key});

  final List<FilterChipItem> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.where((i) => i.warningCount != 0).toList();
    return SizedBox(
      height: AppSizes.minTapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = visible[i];
          return _Chip(
            label: item.label,
            selected: item.selected,
            onTap: item.onTap,
            warningCount: item.warningCount,
          );
        },
      ),
    );
  }
}

/// The sort button (canvas ៧ option គ): the order in use as a label (the
/// reversed label once [reversed]) beside a thin ↑↓ mark. It opens a plain
/// list of orders with a ✓ on the one in use. Tapping an order picks it, or
/// flips its direction when it is already in use.
class SortMenu<T> extends StatelessWidget {
  const SortMenu({
    required this.tooltip,
    required this.options,
    required this.selected,
    required this.reversed,
    required this.onChanged,
    super.key,
  });

  final String tooltip;

  /// Each order: value, icon, label, reversed label. The icon is not drawn;
  /// the list is text and a check.
  final List<(T, IconData, String, String)> options;
  final T selected;
  final bool reversed;
  final void Function(T value, {bool? reversed}) onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final current = options.firstWhere(
      (o) => o.$1 == selected,
      orElse: () => options.first,
    );
    final currentLabel = reversed ? current.$4 : current.$3;
    return PopupMenuButton<T>(
      tooltip: tooltip,
      initialValue: selected,
      onSelected: onChanged,
      // Open below the button, not over what sits beside it.
      position: PopupMenuPosition.under,
      color: t.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(color: t.border),
      ),
      itemBuilder: (_) => [
        for (final (value, _, label, reversedLabel) in options)
          PopupMenuItem(
            value: value,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == selected && reversed ? reversedLabel : label,
                    style: AppTextTheme.body.copyWith(
                      color: value == selected
                          ? t.textPrimary
                          : t.textSecondary,
                      fontWeight: value == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (value == selected) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.check_rounded, size: 20, color: t.textPrimary),
                ],
              ],
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLabel,
                style: AppTextTheme.hint.copyWith(
                  color: t.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              CustomPaint(
                size: const Size.square(18),
                painter: _SortGlyphPainter(
                  active: t.textPrimary,
                  idle: t.textMuted.withValues(alpha: 0.5),
                  up: reversed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ↑ on the left and ↓ on the right, drawn on the design's 24 grid. The
/// arrow for the direction in use is [active] and heavier; the other is
/// [idle]. [up] is the reversed direction.
class _SortGlyphPainter extends CustomPainter {
  _SortGlyphPainter({
    required this.active,
    required this.idle,
    required this.up,
  });

  final Color active;
  final Color idle;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    Paint stroke({required bool on}) => Paint()
      ..color = on ? active : idle
      ..style = PaintingStyle.stroke
      ..strokeWidth = (on ? 2.6 : 2) * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset p(double x, double y) => Offset(x * unit, y * unit);
    final upArrow = Path()
      ..moveTo(p(8, 19).dx, p(8, 19).dy)
      ..lineTo(p(8, 5).dx, p(8, 5).dy)
      ..moveTo(p(4, 9).dx, p(4, 9).dy)
      ..lineTo(p(8, 5).dx, p(8, 5).dy)
      ..lineTo(p(12, 9).dx, p(12, 9).dy);
    final downArrow = Path()
      ..moveTo(p(16, 5).dx, p(16, 5).dy)
      ..lineTo(p(16, 19).dx, p(16, 19).dy)
      ..moveTo(p(12, 15).dx, p(12, 15).dy)
      ..lineTo(p(16, 19).dx, p(16, 19).dy)
      ..lineTo(p(20, 15).dx, p(20, 15).dy);
    // The idle arrow first, so the active one sits on top where they meet.
    canvas
      ..drawPath(up ? downArrow : upArrow, stroke(on: false))
      ..drawPath(up ? upArrow : downArrow, stroke(on: true));
  }

  @override
  bool shouldRepaint(_SortGlyphPainter old) =>
      old.active != active || old.idle != idle || old.up != up;
}

/// Wrapping row of suggestions that fill a field when tapped.
class QuickPickChips extends StatelessWidget {
  const QuickPickChips({
    required this.options,
    required this.onPick,
    this.selected,
    this.trailing,
    super.key,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onPick;

  /// Optional last chip, such as `ទាំងអស់ ›`.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          PickChip(
            label: option,
            selected: option == selected,
            onTap: () => onPick(option),
          ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A suggestion chip (canvas ៤ក): white with a border, or dark with a
/// check when chosen.
class PickChip extends StatelessWidget {
  const PickChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;

  /// Null shows the chip without a tap, e.g. read-only.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onPrimary : t.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Center(
            widthFactor: 1,
            child: Container(
              height: AppSizes.chipHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? t.textPrimary : t.surface,
                border: selected ? null : Border.all(color: t.border),
                borderRadius: BorderRadius.circular(AppSizes.radiusChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_rounded, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppTextTheme.label.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.warningCount,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? warningCount;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final warning = warningCount != null;
    final (bg, fg) = switch ((selected, warning)) {
      (true, _) => (t.textPrimary, t.onPrimary),
      (false, true) => (t.warningBg, t.warningText),
      (false, false) => (t.surfaceMuted, t.textPrimary),
    };
    // The chip is 40 tall; the surrounding 44 is the tap target.
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minTapTarget,
            minWidth: AppSizes.minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: Container(
              height: AppSizes.chipHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppSizes.radiusChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextTheme.label.copyWith(color: fg)),
                  if (warning) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: fg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$warningCount',
                        style: AppTextTheme.hint.copyWith(
                          color: selected ? t.textPrimary : t.warningBg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

/// A list's sort orders as icon and label; the chosen one is darker and
/// bolder, with no fill, and its arrow points down, or up once [reversed].
/// Tapping it again flips it. Not scrolling: keep it to two short labels.
class SortButtons<T> extends StatelessWidget {
  const SortButtons({
    required this.options,
    required this.selected,
    required this.reversed,
    required this.onChanged,
    super.key,
  });

  final List<(T, String)> options;
  final T selected;
  final bool reversed;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (value, label) in options)
          Semantics(
            button: true,
            selected: value == selected,
            child: InkWell(
              onTap: () => onChanged(value),
              borderRadius: BorderRadius.circular(AppSizes.radiusChip),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.minTapTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        value != selected
                            ? Icons.swap_vert_rounded
                            : reversed
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 18,
                        color: value == selected ? t.textPrimary : t.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        label,
                        style: AppTextTheme.hint.copyWith(
                          color: value == selected
                              ? t.textPrimary
                              : t.textMuted,
                          fontWeight: value == selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
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

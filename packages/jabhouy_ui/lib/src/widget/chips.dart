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

/// The sort icon and its dropdown of orders: icon, label (the reversed
/// label once [reversed]) and a ↓ ↑ pair with the active direction filled.
/// Tapping a row picks it, or flips it when already in use; tapping an
/// arrow sets that direction.
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

  /// Each order: value, icon, label, reversed label.
  final List<(T, IconData, String, String)> options;
  final T selected;
  final bool reversed;
  final void Function(T value, {bool? reversed}) onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
      icon: Icon(Icons.sort_rounded, color: t.textSecondary),
      itemBuilder: (_) => [
        for (final (value, icon, label, reversedLabel) in options)
          PopupMenuItem(
            value: value,
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Builder(
              builder: (menuContext) {
                final on = value == selected;
                Widget arrow({required bool up, required String semantics}) {
                  final active = on && reversed == up;
                  return Semantics(
                    button: true,
                    selected: active,
                    label: semantics,
                    child: InkResponse(
                      onTap: () {
                        Navigator.pop(menuContext);
                        onChanged(value, reversed: up);
                      },
                      radius: 20,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? t.textPrimary : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          up
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 18,
                          color: active ? t.onPrimary : t.textMuted,
                        ),
                      ),
                    ),
                  );
                }

                return Row(
                  children: [
                    Icon(icon, size: 20, color: on ? t.textPrimary : t.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        on && reversed ? reversedLabel : label,
                        style: AppTextTheme.body.copyWith(
                          color: on ? t.textPrimary : t.textSecondary,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    arrow(up: false, semantics: label),
                    const SizedBox(width: 4),
                    arrow(up: true, semantics: reversedLabel),
                  ],
                );
              },
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

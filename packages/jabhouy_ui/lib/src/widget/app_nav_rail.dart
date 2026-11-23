import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';
import 'package:jabhouy_ui/src/widget/app_bottom_nav.dart';

/// The tablet counterpart of [AppBottomNav]'s tabs: a vertical rail down
/// the leading edge. The add button floats over the content instead.
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    super.key,
  });

  static const width = 96.0;

  final List<AppNavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: BorderDirectional(end: BorderSide(color: t.dividerStrong)),
      ),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              const SizedBox(height: 16),
              for (final (i, tab) in tabs.indexed)
                _RailItem(
                  tab: tab,
                  selected: i == selectedIndex,
                  onTap: () => onTabChanged(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AppNavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onPrimary : t.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 56,
                height: 36,
                decoration: ShapeDecoration(
                  color: selected ? t.textPrimary : Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: Icon(tab.icon, color: fg, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                textAlign: TextAlign.center,
                style: AppTextTheme.label.copyWith(
                  color: selected ? t.textPrimary : t.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

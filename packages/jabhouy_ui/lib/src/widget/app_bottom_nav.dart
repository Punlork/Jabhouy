import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// One tab in [AppBottomNav].
class AppNavTab {
  const AppNavTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Bottom tabs with a floating extended button above them on the right.
/// The active tab is a dark pill; the button's label follows the tab.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final List<AppNavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final String actionLabel;

  /// Null shows the button disabled.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            0,
            AppSizes.screenPadding,
            12,
          ),
          child: FloatingActionButton.extended(
            onPressed: onAction,
            backgroundColor: t.textPrimary,
            foregroundColor: t.onPrimary,
            shape: const StadiumBorder(),
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel, style: AppTextTheme.label),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface,
            border: Border(top: BorderSide(color: t.dividerStrong)),
          ),
          // Inside the bar, so its white runs under the home indicator.
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
              child: Row(
                children: [
                  for (final (i, tab) in tabs.indexed)
                    Expanded(
                      child: _NavButton(
                        tab: tab,
                        selected: i == selectedIndex,
                        onTap: () => onTabChanged(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
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
    // The whole half is the tap target; the dark pill only hugs the
    // active icon and label, so the add button stays the one big shape.
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: AppSizes.minTapTarget + 4,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: ShapeDecoration(
                color: selected ? t.textPrimary : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, color: fg, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    tab.label,
                    style: AppTextTheme.label.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

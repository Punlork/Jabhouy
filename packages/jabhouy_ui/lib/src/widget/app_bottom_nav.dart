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
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      top: false,
      child: Column(
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
            child: Padding(
              padding: const EdgeInsets.all(8),
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
        ],
      ),
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
    final fg = selected ? t.onPrimary : t.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? t.textPrimary : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: AppSizes.buttonHeight - 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.icon, color: fg),
                const SizedBox(width: 8),
                Text(tab.label, style: AppTextTheme.label.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

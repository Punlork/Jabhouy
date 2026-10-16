import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';
import 'package:jabhouy_ui/src/widget/app_bottom_sheet.dart';

/// Redesign bottom sheet: drag handle, title, close button, scrolling
/// content and an optional footer that stays put.
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.title,
    required this.child,
    this.footer,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppBottomSheet(
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 4, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextTheme.pageTitle.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.close_rounded, color: t.textPrimary),
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
              ),
              child: child,
            ),
          ),
          if (footer != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.dividerStrong)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: footer,
              ),
            ),
        ],
      ),
    );
  }
}

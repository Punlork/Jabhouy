import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';
import 'package:jabhouy_ui/src/widget/app_bottom_sheet.dart';

/// Opens [builder]'s sheet the standard way: [initialSize] of the screen
/// at first; scrolling its content up grows it to [maxSize] before the
/// content scrolls, and a drag down shrinks or closes it. Pass the
/// controller to [AppSheet.scrollController].
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, ScrollController controller)
  builder,
  double initialSize = 0.6,
  double maxSize = 0.92,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: initialSize,
    minChildSize: initialSize * 0.5,
    maxChildSize: maxSize,
    snap: true,
    snapSizes: [initialSize],
    builder: builder,
  ),
);

/// Redesign bottom sheet: drag handle, a title (or a custom [header]),
/// close button, scrolling content and an optional footer that stays put.
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.child,
    this.title,
    this.header,
    this.footer,
    this.scrollController,
    super.key,
  }) : assert(title != null || header != null, 'a title or a header');

  final String? title;

  /// Replaces the title, e.g. a thumbnail with a name and a tag.
  final Widget? header;
  final Widget child;
  final Widget? footer;

  /// From [showAppSheet], so scrolling the content resizes the sheet.
  final ScrollController? scrollController;

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
              crossAxisAlignment: header == null
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Expanded(
                  child:
                      header ??
                      Text(
                        title!,
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
              controller: scrollController,
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

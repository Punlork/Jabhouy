import 'package:flutter/widgets.dart';
import 'package:jabhouy_ui/src/layout/breakpoints.dart';

/// Centers [child] and stops it growing past [maxWidth]. On a phone the
/// screen is narrower than that, so it changes nothing.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    super.key,
  });

  /// A form or settings column.
  const ContentWidth.form({required this.child, super.key})
    : maxWidth = AppBreakpoints.maxFormWidth;

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    // Height follows the child, so a short sheet stays short.
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

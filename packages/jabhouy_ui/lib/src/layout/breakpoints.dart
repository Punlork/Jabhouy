import 'package:flutter/widgets.dart';

/// Width breakpoints. Tablet is a width rule, not a device check, so a
/// phone in landscape or an iPad in split view behaves by the room it has.
abstract final class AppBreakpoints {
  static const tablet = 600.0;
  static const wide = 900.0;

  /// Widest a form or settings column grows.
  static const maxFormWidth = 640.0;

  /// Widest a list or dashboard grows.
  static const maxContentWidth = 1100.0;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  /// Grid columns for [width]: 2 on a phone, 3 on a tablet, 4 when wide.
  static int gridColumns(double width) {
    if (width >= wide) return 4;
    if (width >= tablet) return 3;
    return 2;
  }
}

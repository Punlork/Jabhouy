import 'package:flutter/material.dart';

/// The four strings this package's widgets put on screen.
///
/// `LoadingOverlay`, `EmptyView` and `ImgClipboardMixin` each read one or
/// two labels from `AppLocalizations`, which lives in the app package and
/// is generated from its ARB files. A shared widget package cannot reach
/// it, and should not own the app's copy either. So the package declares
/// what it needs and the app supplies it, the same shape as
/// `IncomeDiagnostics` and `SyncTransport`.
abstract class UiStrings {
  String get loading;
  String get noItemFound;
  String get cancel;
  String get imgFound;
}

/// Installs a [UiStrings] for the widgets below it.
///
/// Wrap the app once, under the `Localizations` widget so the
/// implementation can read `AppLocalizations.of(context)`.
class UiStringsScope extends InheritedWidget {
  const UiStringsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  final UiStrings strings;

  static UiStrings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<UiStringsScope>();
    if (scope == null) {
      throw FlutterError(
        'No UiStringsScope found. Wrap the app in a UiStringsScope so '
        'jabhouy_ui widgets can read their labels.',
      );
    }
    return scope.strings;
  }

  @override
  bool updateShouldNotify(UiStringsScope oldWidget) =>
      strings != oldWidget.strings;
}

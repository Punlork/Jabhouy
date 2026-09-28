import 'package:flutter/material.dart';

/// The last routed `BuildContext`, for the call sites that have none.
///
/// It lived in `app_routes.dart` because the router's `pageBuilder` is
/// what assigns it. That put a snack bar's dependency inside the file
/// that wires every feature, which is the cycle this package exists to
/// break. Assignment is still the app's job; holding the value is not.
class GlobalContext {
  GlobalContext._();
  static BuildContext? _currentContext;

  static BuildContext get currentContext {
    if (_currentContext == null) {
      throw FlutterError('GlobalContext: _currentContext is null');
    }
    return _currentContext!;
  }

  static set currentContext(BuildContext context) {
    _currentContext = context;
  }
}

/// Build tier the app was launched as.
///
/// Each `main_*.dart` entrypoint passes its own value into [bootstrap] so
/// runtime tooling (currently the debug overlay) can pick the right
/// capability tier without inspecting `kReleaseMode` at each call site.
enum AppFlavor {
  development,
  staging,
  production;

  bool get isProduction => this == AppFlavor.production;
}

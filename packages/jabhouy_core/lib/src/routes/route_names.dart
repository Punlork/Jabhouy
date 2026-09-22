/// Every route's name, and the one-liner that turns it into a path.
///
/// These lived in `app_routes.dart` beside the GoRouter config, which
/// imports every feature — so a feature reading one route name imported
/// the whole graph. The names are shared vocabulary and the wiring is the
/// app shell's; only the first half has to be reachable from a package.
extension StringExtension on String {
  String get toPath => '/$this';
}

class AppRoutes {
  static const home = 'home';
  static const signin = 'signin';
  static const signup = 'signup';
  static const formShop = 'form_shop';
  static const formLoaner = 'form_loaner';
  static const category = 'category';
  static const customer = 'customer';
  static const profile = 'profile';
  static const settings = 'settings';
  static const appDiagnostics = 'app_diagnostics';
  static const incomeDiagnostics = 'income_diagnostics';
}

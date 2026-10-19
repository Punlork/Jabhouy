import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Where the router sends [path] for [authState], or null to stay.
///
/// Pure so the rules can be tested without building the router.
String? authRedirect(AuthState authState, String path, FeatureFlags flags) {
  if (authState is Unauthenticated && !_allowedUnauthenticated.contains(path)) {
    return AppRoutes.signin.toPath;
  }
  if (authState is Authenticated) {
    // A User who joined with Google has no Username until they pick one.
    final picker = AppRoutes.chooseUsername.toPath;
    if (!authState.user.hasUsername) return path == picker ? null : picker;
    if (!_allowedAuthenticated(flags).contains(path)) return AppRoutes.home.toPath;
  }
  return null;
}

final _allowedUnauthenticated = {
  AppRoutes.signin.toPath,
  AppRoutes.signup.toPath,
};

Set<String> _allowedAuthenticated(FeatureFlags flags) {
  final diagnostics = flags.isEnabled(Feature.diagnostics);
  return {
    AppRoutes.home.toPath,
    '${AppRoutes.home.toPath}${AppRoutes.formShop.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.formItem.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.formLoaner.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.category.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.profile.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.settings.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.priceSettings.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.categoriesUnits.toPath}',
    if (diagnostics) '${AppRoutes.home.toPath}${AppRoutes.appDiagnostics.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.customer.toPath}',
    // Left out when income is off, so the redirect sends a stale link home
    // instead of to a page with no bloc.
    if (flags.isEnabled(Feature.income) && diagnostics)
      '${AppRoutes.home.toPath}${AppRoutes.incomeDiagnostics.toPath}',
  };
}

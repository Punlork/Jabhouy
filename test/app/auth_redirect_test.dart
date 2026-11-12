import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

void main() {
  const flags = FixedFeatureFlags({});
  const signedOut = Unauthenticated();
  const signedIn = Authenticated(User(id: 'u1', username: 'dara'));
  final home = AppRoutes.home.toPath;
  final signin = AppRoutes.signin.toPath;
  final settings = '$home${AppRoutes.settings.toPath}';

  test('signed out on a protected path goes to sign-in', () {
    expect(authRedirect(signedOut, settings, flags), signin);
    expect(authRedirect(signedOut, home, flags), signin);
  });

  test('signed out on sign-in stays; there is no sign-up page', () {
    expect(authRedirect(signedOut, signin, flags), isNull);
    expect(authRedirect(signedOut, '/signup', flags), signin);
  });

  test('authenticated on an unknown path goes home', () {
    expect(authRedirect(signedIn, '/nowhere', flags), home);
    expect(authRedirect(signedIn, signin, flags), home);
  });

  test('authenticated on an allowed path stays', () {
    expect(authRedirect(signedIn, home, flags), isNull);
    expect(authRedirect(signedIn, settings, flags), isNull);
    final itemForm = '$home${AppRoutes.formItem.toPath}';
    expect(authRedirect(signedIn, itemForm, flags), isNull);
    final prices = '$home${AppRoutes.priceSettings.toPath}';
    expect(authRedirect(signedIn, prices, flags), isNull);
  });

  test('income diagnostics is reachable only with income and diagnostics on', () {
    final path = '$home${AppRoutes.incomeDiagnostics.toPath}';

    expect(authRedirect(signedIn, path, const FixedFeatureFlags({Feature.diagnostics})), home);
    expect(authRedirect(signedIn, path, const FixedFeatureFlags({Feature.diagnostics, Feature.income})), isNull);
  });

  test('a User without a Username is not held back', () {
    const noUsername = Authenticated(User(id: 'g1', email: 'a@gmail.com'));

    expect(authRedirect(noUsername, home, flags), isNull);
    expect(authRedirect(noUsername, settings, flags), isNull);
  });
}

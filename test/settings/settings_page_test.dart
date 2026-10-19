import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy/membership/membership.dart';
import 'package:jabhouy/settings/settings.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _MockSignoutBloc extends MockBloc<SignoutEvent, SignoutState>
    implements SignoutBloc {}

class _MockPriceSettings extends MockCubit<PriceSettings?>
    implements PriceSettingsCubit {}

void main() {
  late _MockAppBloc app;
  late _MockSignoutBloc signout;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Jabhouy',
      packageName: 'com.pl.shop_management',
      version: '1.0.27',
      buildNumber: '32',
      buildSignature: '',
    );
    await getIt.reset();
    final shop = CurrentShop(const FakeMeApi());
    await shop.load('u1');
    getIt
      ..registerSingleton<FeatureFlags>(const FixedFeatureFlags({}))
      ..registerSingleton(shop);
    app = _MockAppBloc();
    when(() => app.state).thenReturn(
      const AppState(
        locale: Locale('km'),
        isGridView: false,
        isDarkMode: false,
        isAppLogCaptureEnabled: false,
        isNetworkLogCaptureEnabled: false,
        deviceRole: DeviceRole.main,
      ),
    );
    signout = _MockSignoutBloc();
    when(() => signout.state).thenReturn(SignoutInitial());
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    final auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(
      const Authenticated(User(id: 'u1', name: 'ដារ៉ា', username: 'dara')),
    );
    final prices = _MockPriceSettings();
    when(() => prices.state).thenReturn(
      const PriceSettings(useWholesale: true),
    );
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppBloc>.value(value: app),
          BlocProvider<AuthBloc>.value(value: auth),
          BlocProvider<SignoutBloc>.value(value: signout),
          BlocProvider<PriceSettingsCubit>.value(value: prices),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('km'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('profile card shows the user and their role', (tester) async {
    await pumpPage(tester);

    expect(find.text('ដារ៉ា'), findsOneWidget);
    expect(find.text('ម្ចាស់ហាង'), findsOneWidget);
  });

  testWidgets('the prices row sums up the shop settings', (tester) async {
    await pumpPage(tester);

    expect(find.text('តម្លៃ និងរូបិយប័ណ្ណ'), findsOneWidget);
    expect(find.text(r'$1 = 4,000 ៛ · លក់ដុំ · ដើម'), findsOneWidget);
  });

  testWidgets('sign out asks first', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('ចាកចេញ'));
    await tester.pumpAndSettle();
    expect(find.text('តើអ្នកប្រាកដថាចង់ចាកចេញទេ?'), findsOneWidget);
    await tester.tap(find.text('ចាកចេញ').last);
    await tester.pumpAndSettle();
    verify(() => signout.add(const SignoutSubmitted())).called(1);
  });
}

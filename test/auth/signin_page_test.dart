import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _MockSigninBloc extends MockBloc<SigninEvent, SigninState>
    implements SigninBloc {}

void main() {
  late _MockSigninBloc signin;

  Future<void> pumpPage(WidgetTester tester, {required bool google}) async {
    await getIt.reset();
    getIt
      ..registerSingleton<FeatureFlags>(
        FixedFeatureFlags({if (google) Feature.googleSignIn}),
      )
      ..registerFactory<SigninBloc>(() => signin);
    final auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(const Unauthenticated());
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('km'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SigninPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    signin = _MockSigninBloc();
    when(() => signin.state).thenReturn(SigninInitial());
  });

  tearDown(getIt.reset);

  testWidgets('Google first, then ឬ, the password form, and no sign-up', (
    tester,
  ) async {
    await pumpPage(tester, google: true);

    expect(find.text('បន្តជាមួយ Google'), findsOneWidget);
    expect(find.text('ឬ'), findsOneWidget);
    expect(find.text('ឈ្មោះអ្នកប្រើ ឬអ៊ីមែល'), findsOneWidget);
    expect(find.text('លេខសម្ងាត់'), findsOneWidget);
    expect(find.text('ចូល'), findsOneWidget);
    expect(find.textContaining('ចុះឈ្មោះ'), findsNothing);
    final google = tester.getTopLeft(find.text('បន្តជាមួយ Google')).dy;
    expect(google, lessThan(tester.getTopLeft(find.text('ឬ')).dy));
  });

  testWidgets('with Google off, no Google button and no ឬ', (tester) async {
    await pumpPage(tester, google: false);

    expect(find.text('បន្តជាមួយ Google'), findsNothing);
    expect(find.text('ឬ'), findsNothing);
    expect(find.text('ចូល'), findsOneWidget);
  });

  testWidgets('ចូល submits the typed account and password', (tester) async {
    await pumpPage(tester, google: false);

    await tester.enterText(find.byType(TextFormField).first, 'dara');
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await tester.tap(find.text('ចូល'));
    await tester.pump();

    verify(
      () => signin.add(
        const SigninSubmitted(username: 'dara', password: 'secret1'),
      ),
    ).called(1);
  });
}

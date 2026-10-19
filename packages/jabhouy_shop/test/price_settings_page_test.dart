import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  _Scope(this.role);

  @override
  final MemberRole role;
  @override
  String get shopId => 's1';
  @override
  bool get syncs => false;
  @override
  String get userId => 'u1';
}

void main() {
  late AppDatabase db;
  late ItemRepository repo;

  Future<void> pumpPage(WidgetTester tester, MemberRole role) async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    final scope = _Scope(role);
    repo = ItemRepository(
      ItemDao(db),
      scope,
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => PriceSettingsCubit(repo, scope)..load(),
          child: const PriceSettingsPage(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<PriceSettings> saved(WidgetTester tester) async =>
      (await tester.runAsync(repo.priceSettings))!;

  testWidgets('the owner ticks wholesale and it is saved', (tester) async {
    await pumpPage(tester, MemberRole.owner);

    await tester.tap(find.text('តម្លៃលក់ដុំ'));
    await settle(tester);

    expect((await saved(tester)).useWholesale, isTrue);
    await tester.runAsync(db.close);
  });

  testWidgets('a new rate is saved only after confirming', (tester) async {
    await pumpPage(tester, MemberRole.owner);

    await tester.enterText(find.byKey(PriceSettingsPage.rateKey), '4100');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.text('ការជំពាក់ចាស់នៅតែប្រើអត្រាដើមរបស់វា។'), findsOneWidget);
    expect((await saved(tester)).khrPerUsd, 4000, reason: 'not yet');

    await tester.tap(find.text('រក្សាទុក'));
    await settle(tester);
    expect((await saved(tester)).khrPerUsd, 4100);
    await tester.runAsync(db.close);
  });

  testWidgets('everyone else sees the settings read-only', (tester) async {
    await pumpPage(tester, MemberRole.editor);

    expect(find.text('មានតែម្ចាស់ហាងទេដែលអាចកែការកំណត់ហាងបាន'), findsOneWidget);
    await tester.tap(find.text('តម្លៃលក់ដុំ'));
    await settle(tester);
    expect((await saved(tester)).useWholesale, isFalse);
    final rate = tester.widget<TextField>(find.byKey(PriceSettingsPage.rateKey));
    expect(rate.enabled, isFalse);
    await tester.runAsync(db.close);
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

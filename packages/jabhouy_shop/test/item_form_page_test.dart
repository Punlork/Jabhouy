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
  @override
  String get shopId => 's1';
  @override
  bool get syncs => false;
  @override
  MemberRole get role => MemberRole.owner;
  @override
  String get userId => 'u1';
}

void main() {
  late AppDatabase db;
  late ItemRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    repo = ItemRepository(
      ItemDao(db),
      _Scope(),
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
  });

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => ItemFormCubit(repo)..load(),
          child: const ItemFormPage(),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Finder rowField(int row, int field) => find
      .descendant(
        of: find.byType(PriceRowEditor).at(row),
        matching: find.byType(TextField),
      )
      .at(field);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('រក្សាទុក'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('ដប + កេះ ×24 in one form saves one item with two prices',
      (tester) async {
    await pumpForm(tester);
    // Empty fields show the design's examples.
    for (final hint in ['ឧ. អង្ករផ្កាម្លិះ', 'ឧ. ដប', '1', 'ឧ. 3,000']) {
      expect(find.text(hint), findsOneWidget, reason: hint);
    }

    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'Coca-Cola');
    await tester.enterText(rowField(0, 0), 'ដប');
    await tester.enterText(rowField(0, 2), '3000');
    await tester.tap(find.textContaining('បន្ថែមតម្លៃ'));
    await tester.pumpAndSettle();
    await tester.enterText(rowField(1, 0), 'កេះ');
    await tester.enterText(rowField(1, 1), '24');
    await tester.enterText(rowField(1, 2), '60000');
    await save(tester);

    final items = await tester.runAsync(() => repo.watchItems().first);
    expect(items!.single.name, 'Coca-Cola');
    expect(items.single.prices.map((p) => (p.unit, p.packQty, p.price)), [
      ('ដប', null, 3000),
      ('កេះ', 24, 60000),
    ]);
    await tester.runAsync(db.close);
  });

  testWidgets('adding a nickname shows it as a chip and saves it',
      (tester) async {
    await pumpForm(tester);

    await tester.tap(find.textContaining('+ ឈ្មោះផ្សេង'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ទឹកធំ');
    await tester.tap(find.text('រក្សាទុក').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InputChip, 'ទឹកធំ'), findsOneWidget);
    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'ទឹកអូគូលេនធំ');
    await tester.enterText(rowField(0, 0), 'ដប');
    await save(tester);

    final items = await tester.runAsync(() => repo.watchItems().first);
    expect(items!.single.nicknames, ['ទឹកធំ']);
    await tester.runAsync(db.close);
  });

  testWidgets('saving with problems shows each message and writes nothing',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(rowField(0, 0), 'កេះ');
    await tester.enterText(rowField(0, 1), '0');
    await tester.enterText(rowField(0, 2), '3000.5');
    await save(tester);

    expect(find.text('សូមបញ្ចូលឈ្មោះទំនិញ'), findsOneWidget);
    expect(find.text('ចំនួនត្រូវធំជាង ០'), findsOneWidget);
    expect(find.text('តម្លៃរៀលមិនអាចមានទសភាគ'), findsOneWidget);
    final items = await tester.runAsync(() => repo.watchItems().first);
    expect(items, isEmpty);
    await tester.runAsync(db.close);
  });
}

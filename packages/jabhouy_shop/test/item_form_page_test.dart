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

  /// A field of the one open price row: unit 0, count 1, price 2.
  Finder openField(int field) => find
      .descendant(
        of: find.byType(PriceRowEditor),
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
    // Unit, count and price line up at the design's 50 px.
    for (final field in [0, 1, 2]) {
      expect(tester.getSize(openField(field)).height, 50, reason: '$field');
    }
    // Empty fields show the design's examples.
    for (final hint in ['ឧ. អង្ករផ្កាម្លិះ', 'ឧ. ដប', '1', 'ឧ. 3,000']) {
      expect(find.text(hint), findsOneWidget, reason: hint);
    }

    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'Coca-Cola');
    await tester.enterText(openField(0), 'ដប');
    await tester.enterText(openField(2), '3000');
    await tester.tap(find.textContaining('បន្ថែមតម្លៃ'));
    await tester.pumpAndSettle();
    await tester.enterText(openField(0), 'កេះ');
    await tester.enterText(openField(1), '24');
    await tester.enterText(openField(2), '60000');
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
    await tester.enterText(openField(0), 'ដប');
    await save(tester);

    final items = await tester.runAsync(() => repo.watchItems().first);
    expect(items!.single.nicknames, ['ទឹកធំ']);
    await tester.runAsync(db.close);
  });

  testWidgets('the open price row offers the unit chips', (tester) async {
    await tester.runAsync(() async {
      await repo.saveCategory(
        const ItemCategory(
          id: 'drinks',
          name: 'ភេសជ្ជៈ',
          units: [CategoryUnit(unit: 'ដប'), CategoryUnit(unit: 'កេះ')],
        ),
      );
      // The form opens on the last used category.
      await repo.saveItem(
        const Item(id: 'old', name: 'old', categoryId: 'drinks', prices: []),
      );
    });
    await pumpForm(tester);
    await tester.tap(find.textContaining('បន្ថែមតម្លៃ'));
    await tester.pumpAndSettle();

    // The new row is the open one, and it carries the chips.
    await tester.tap(
      find.descendant(
        of: find.byType(PriceRowEditor),
        matching: find.text('កេះ'),
      ),
    );
    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'Coca-Cola');
    await save(tester);

    final items = await tester.runAsync(() => repo.watchItems().first);
    final coke = items!.firstWhere((i) => i.name == 'Coca-Cola');
    expect(coke.prices.single.unit, 'កេះ', reason: 'row 1 left empty');
    await tester.runAsync(db.close);
  });

  testWidgets('one row is open; the others collapse to a summary line',
      (tester) async {
    await pumpForm(tester);
    await tester.enterText(openField(0), 'ដប');
    await tester.enterText(openField(2), '3000');
    await tester.tap(find.textContaining('បន្ថែមតម្លៃ'));
    await tester.pumpAndSettle();

    expect(find.byType(PriceRowEditor), findsOneWidget);
    final summary = find.byType(PriceRowSummary);
    expect(summary, findsOneWidget);
    expect(
      find.descendant(of: summary, matching: find.text('3,000 ៛')),
      findsOneWidget,
    );

    // Opening the first row closes the new, empty one.
    await tester.tap(summary);
    await tester.pumpAndSettle();
    expect(find.byType(PriceRowEditor), findsOneWidget);
    expect(find.byType(PriceRowSummary), findsOneWidget);
    expect(find.text('3,000'), findsOneWidget, reason: 'its text is kept');
    await tester.runAsync(db.close);
  });

  testWidgets('saving opens the first row with a problem', (tester) async {
    await pumpForm(tester);
    await tester.enterText(openField(0), 'កេះ');
    await tester.enterText(openField(1), '0');
    await tester.tap(find.textContaining('បន្ថែមតម្លៃ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'Coca-Cola');
    await save(tester);

    expect(find.text('ចំនួនត្រូវធំជាង ០'), findsOneWidget);
    expect(find.text('កេះ'), findsOneWidget, reason: 'the bad row is open');
    await tester.runAsync(db.close);
  });

  testWidgets('saving with problems shows each message and writes nothing',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(openField(0), 'កេះ');
    await tester.enterText(openField(1), '0');
    await tester.enterText(openField(2), '3000.5');
    await save(tester);

    expect(find.text('សូមបញ្ចូលឈ្មោះទំនិញ'), findsOneWidget);
    expect(find.text('ចំនួនត្រូវធំជាង ០'), findsOneWidget);
    expect(find.text('តម្លៃរៀលមិនអាចមានទសភាគ'), findsOneWidget);
    final items = await tester.runAsync(() => repo.watchItems().first);
    expect(items, isEmpty);
    await tester.runAsync(db.close);
  });
}

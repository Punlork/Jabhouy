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

  Future<void> pumpForm(
    WidgetTester tester, {
    Future<String?> Function(BuildContext)? scan,
    String? barcode,
    String? name,
  }) async {
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
          child: ItemFormPage(scanBarcode: scan, barcode: barcode, name: name),
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

  Future<String?> savedBarcode(WidgetTester tester) async {
    final items = await tester.runAsync(() => repo.watchItems().first);
    return items!.single.prices.single.barcode;
  }

  Future<void> openAdd(WidgetTester tester) async {
    await tester.tap(find.textContaining('បន្ថែមតម្លៃទំនិញ'));
    await tester.pumpAndSettle();
  }

  /// Adds a price through the sheet.
  Future<void> addPrice(
    WidgetTester tester, {
    required String unit,
    String? count,
    String? price,
  }) async {
    await openAdd(tester);
    await tester.enterText(openField(0), unit);
    if (count != null) await tester.enterText(openField(1), count);
    if (price != null) await tester.enterText(openField(2), price);
    await tester.tap(find.text('បន្ថែម'));
    await tester.pumpAndSettle();
  }

  testWidgets('the row barcode button scans a code into its row', (
    tester,
  ) async {
    await pumpForm(tester, scan: (_) async => '885');
    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'Coca-Cola');
    await openAdd(tester);
    await tester.enterText(openField(0), 'ដប');
    await tester.enterText(openField(2), '3000');
    await tester.tap(find.byTooltip('ស្កេនបាកូដ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('បន្ថែម'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(await savedBarcode(tester), '885');
  });

  testWidgets('without a scanner the row has no barcode button', (
    tester,
  ) async {
    await pumpForm(tester);
    await openAdd(tester);
    expect(find.byTooltip('ស្កេនបាកូដ'), findsNothing);
  });

  testWidgets('an item added from a scan starts with its barcode', (
    tester,
  ) async {
    await pumpForm(tester, barcode: '885');
    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'Coca-Cola');
    await tester.tap(find.byType(PriceRowSummary));
    await tester.pumpAndSettle();
    await tester.enterText(openField(0), 'ដប');
    await tester.enterText(openField(2), '3000');
    await tester.tap(find.text('រួចរាល់'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(await savedBarcode(tester), '885');
  });

  testWidgets('an item added from a search starts with the typed name', (
    tester,
  ) async {
    await pumpForm(tester, name: 'ទឹកធំ');
    expect(find.text('ទឹកធំ'), findsOneWidget);
  });

  testWidgets('ដប + កេះ ×24 in one form saves one item with two prices', (
    tester,
  ) async {
    await pumpForm(tester);
    expect(find.text('ឧ. អង្ករផ្កាម្លិះ'), findsOneWidget);
    expect(find.text('មិនទាន់មានតម្លៃ'), findsOneWidget, reason: 'no rows yet');

    await openAdd(tester);
    // Unit, count and price line up at the design's 50 px.
    for (final field in [0, 1, 2]) {
      expect(tester.getSize(openField(field)).height, 50, reason: '$field');
    }
    // Empty fields show the design's examples.
    for (final hint in ['ឧ. ដប', '1', 'ឧ. 3,000']) {
      expect(find.text(hint), findsOneWidget, reason: hint);
    }
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'Coca-Cola');
    await addPrice(tester, unit: 'ដប', price: '3000');
    await addPrice(tester, unit: 'កេះ', count: '24', price: '60000');
    expect(find.byType(PriceRowSummary), findsNWidgets(2));
    await save(tester);

    final items = await tester.runAsync(() => repo.watchItems().first);
    expect(items!.single.name, 'Coca-Cola');
    expect(items.single.prices.map((p) => (p.unit, p.packQty, p.price)), [
      ('ដប', null, 3000),
      ('កេះ', 24, 60000),
    ]);
    await tester.runAsync(db.close);
  });

  testWidgets('adding a nickname shows it as a chip and saves it', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.textContaining('+ ឈ្មោះផ្សេង'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ទឹកធំ');
    await tester.tap(find.text('រក្សាទុក').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InputChip, 'ទឹកធំ'), findsOneWidget);
    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'ទឹកអូគូលេនធំ');
    await addPrice(tester, unit: 'ដប');
    await save(tester);

    final items = await tester.runAsync(() => repo.watchItems().first);
    expect(items!.single.nicknames, ['ទឹកធំ']);
    await tester.runAsync(db.close);
  });

  testWidgets('the price sheet offers the unit chips', (tester) async {
    await tester.runAsync(() async {
      await repo.saveCategory(
        const ItemCategory(
          id: 'drinks',
          name: 'ភេសជ្ជៈ',
          units: [
            CategoryUnit(unit: 'ដប'),
            CategoryUnit(unit: 'កេះ'),
          ],
        ),
      );
      // The form opens on the last used category.
      await repo.saveItem(
        const Item(id: 'old', name: 'old', categoryId: 'drinks', prices: []),
      );
    });
    await pumpForm(tester);
    await openAdd(tester);

    // The price sheet carries the chips.
    await tester.tap(
      find.descendant(
        of: find.byType(PriceRowEditor),
        matching: find.text('កេះ'),
      ),
    );
    await tester.tap(find.text('បន្ថែម'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'Coca-Cola');
    await save(tester);

    final items = await tester.runAsync(() => repo.watchItems().first);
    final coke = items!.firstWhere((i) => i.name == 'Coca-Cola');
    expect(coke.prices.single.unit, 'កេះ');
    await tester.runAsync(db.close);
  });

  testWidgets('a price shows as a row; tapping it edits, លុប removes it', (
    tester,
  ) async {
    await pumpForm(tester);
    await addPrice(tester, unit: 'ដប', price: '3000');

    expect(find.byType(PriceRowSummary), findsOneWidget);
    expect(find.text('3,000 ៛'), findsOneWidget);
    expect(find.text('មិនទាន់មានតម្លៃ'), findsNothing);

    await tester.tap(find.byType(PriceRowSummary));
    await tester.pumpAndSettle();
    expect(find.text('កែតម្លៃ'), findsOneWidget);
    await tester.enterText(openField(2), '3500');
    await tester.tap(find.text('រួចរាល់'));
    await tester.pumpAndSettle();
    expect(find.text('3,500 ៛'), findsOneWidget);

    await tester.tap(find.byType(PriceRowSummary));
    await tester.pumpAndSettle();
    await tester.tap(find.text('លុបតម្លៃនេះ'));
    await tester.pumpAndSettle();
    expect(find.byType(PriceRowSummary), findsNothing);
    expect(find.text('មិនទាន់មានតម្លៃ'), findsOneWidget);
    await tester.runAsync(db.close);
  });

  testWidgets('saving a barcode another item uses reopens that price', (
    tester,
  ) async {
    await tester.runAsync(
      () => repo.saveItem(
        const Item(
          id: 'old',
          name: 'Old',
          prices: [
            PriceOption(
              id: 'p',
              unit: 'ដប',
              currency: Currency.khr,
              barcode: '885',
            ),
          ],
        ),
      ),
    );
    await pumpForm(tester, barcode: '885');
    await tester.enterText(find.byKey(ItemFormPage.nameKey), 'Coca-Cola');
    await save(tester);

    expect(find.text('បាកូដនេះប្រើរួចហើយសម្រាប់ «Old»'), findsOneWidget);
    expect(find.text('កែតម្លៃ'), findsOneWidget, reason: 'the sheet is open');
    await tester.runAsync(db.close);
  });

  testWidgets('saving with no name shows the message and writes nothing', (
    tester,
  ) async {
    await pumpForm(tester);
    await save(tester);

    expect(find.text('សូមបញ្ចូលឈ្មោះទំនិញ'), findsOneWidget);
    final items = await tester.runAsync(() => repo.watchItems().first);
    expect(items, isEmpty);
    await tester.runAsync(db.close);
  });
}

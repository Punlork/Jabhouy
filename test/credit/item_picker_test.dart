import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/credit/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  @override
  MemberRole get role => MemberRole.owner;
  @override
  String get shopId => 's1';
  @override
  bool get syncs => false;
  @override
  String get userId => 'u1';
}

PriceOption _option(
  String id,
  String unit,
  int? price, {
  Currency currency = Currency.khr,
  int? packQty,
}) => PriceOption(
  id: id,
  unit: unit,
  currency: currency,
  price: price,
  packQty: packQty,
);

void main() {
  late AppDatabase db;
  List<CreditLine>? picked;

  Future<void> pump(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(WidgetTester tester) async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    final items = ItemRepository(
      ItemDao(db),
      _Scope(),
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
    await tester.runAsync(() async {
      await items.saveCategory(
        const ItemCategory(id: 'drinks', name: 'ភេសជ្ជៈ'),
      );
      await items.saveItem(
        Item(
          id: 'coke',
          name: 'ទឹកអូគូលេនធំ',
          categoryId: 'drinks',
          prices: [
            _option('p1', 'ដប', 3000),
            _option('p2', 'កេះ', 750, currency: Currency.usd, packQty: 24),
          ],
        ),
      );
      await items.saveItem(
        Item(
          id: 'rice',
          name: 'អង្ករផ្កាម្លិះ',
          prices: [_option('p3', 'គីឡូ', 3800), _option('p4', 'បេ', null)],
        ),
      );
    });
    picked = null;
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await showItemPicker(
                context,
                items,
                currency: Currency.khr,
                khrPerUsd: 4000,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await pump(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }

  Finder plusOf(String price) => find.descendant(
    of: find.ancestor(of: find.text(price), matching: find.byType(Row)).first,
    matching: find.byIcon(Icons.add_rounded),
  );

  testWidgets('2 ដប + 5 គីឡូ: two items, 25,000 ៛, and two lines back', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('បានជ្រើស 0 មុខ'), findsOneWidget);

    await tester.tap(plusOf('3,000 ៛'));
    await pump(tester);
    await tester.tap(find.byIcon(Icons.add_rounded).first); // the ដប stepper
    await pump(tester);
    await tester.tap(plusOf('3,800 ៛'));
    await pump(tester);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byIcon(Icons.add_rounded).at(2));
      await pump(tester);
    }

    expect(find.text('បានជ្រើស 2 មុខ'), findsOneWidget);
    expect(find.text('25,000 ៛'), findsOneWidget);
    expect(find.text(r'≈ $6.25'), findsOneWidget);

    await tester.tap(find.text('បន្ថែមទៅការជំពាក់'));
    await pump(tester);
    expect(picked!.map((l) => (l.name, l.unit, l.qty, l.unitPrice)), [
      ('ទឹកអូគូលេនធំ', 'ដប', 2, 3000),
      ('អង្ករផ្កាម្លិះ', 'គីឡូ', 5, 3800),
    ]);
    await close(tester);
  });

  testWidgets('a \$ option converts into the Credit\'s riel', (tester) async {
    await open(tester);

    await tester.tap(plusOf(r'$7.50'));
    await pump(tester);

    expect(find.text('30,000 ៛'), findsOneWidget, reason: r'$7.50 at 4,000');
    await close(tester);
  });

  testWidgets('no price: shown as missing, cannot be added; nothing: no add', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('មិនទាន់មានតម្លៃ'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'បន្ថែមទៅការជំពាក់'),
    );
    expect(button.onPressed, isNull, reason: 'nothing chosen yet');
    await close(tester);
  });

  testWidgets('search and the category chip narrow the list', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'អង្ករ');
    await pump(tester);
    expect(find.text('អង្ករផ្កាម្លិះ'), findsOneWidget);
    expect(find.text('ទឹកអូគូលេនធំ'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await pump(tester);
    await tester.tap(find.text('ភេសជ្ជៈ'));
    await pump(tester);
    expect(find.text('ទឹកអូគូលេនធំ'), findsOneWidget);
    expect(find.text('អង្ករផ្កាម្លិះ'), findsNothing);
    await close(tester);
  });
}

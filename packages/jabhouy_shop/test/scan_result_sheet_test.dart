import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

const _water = Item(
  id: 'water',
  name: 'ទឹកអូគូលេនធំ',
  prices: [
    PriceOption(
      id: 'bottle',
      unit: 'ដប',
      currency: Currency.khr,
      price: 3000,
      barcode: '885',
    ),
    PriceOption(
      id: 'pack',
      unit: 'កេះ',
      packQty: 24,
      currency: Currency.khr,
      price: 60000,
      sortOrder: 1,
    ),
  ],
);

void main() {
  late Object? result;

  Future<void> open(WidgetTester tester, List<Item> items) async {
    result = 'unset';
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showScanResult(
              context,
              code: '885',
              items: items,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('one match shows the scanned row big, the others smaller', (
    tester,
  ) async {
    await open(tester, [_water]);

    expect(find.text('រកឃើញ · 885'), findsOneWidget);
    expect(find.text('ទឹកអូគូលេនធំ'), findsOneWidget);
    expect(find.text('បាកូដនេះ'), findsOneWidget);
    expect(find.text('3,000 ៛'), findsOneWidget);
    expect(find.text('កេះ (24)'), findsOneWidget);
    expect(
      tester.getSize(find.text('3,000 ៛')).height,
      greaterThan(tester.getSize(find.text('60,000 ៛')).height),
    );

    await tester.tap(find.text('មើលលម្អិត'));
    await tester.pumpAndSettle();
    expect(result, same(_water));
  });

  testWidgets('scan next closes the sheet with nothing', (tester) async {
    await open(tester, [_water]);

    await tester.tap(find.text('ស្កេនបន្ទាប់'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('several matches are listed to pick from', (tester) async {
    const twin = Item(
      id: 'twin',
      name: 'ទឹកអូគូលេន',
      prices: [
        PriceOption(
          id: 'b',
          unit: 'ដប',
          currency: Currency.khr,
          price: 2500,
          barcode: '885',
        ),
      ],
    );
    await open(tester, [_water, twin]);

    expect(find.text('មើលលម្អិត'), findsNothing);
    await tester.tap(find.text('ទឹកអូគូលេន'));
    await tester.pumpAndSettle();
    expect(result, same(twin));
  });

  testWidgets('an unknown code offers to add an item with it', (tester) async {
    await open(tester, []);

    expect(find.text('រកមិនឃើញ · 885'), findsOneWidget);
    await tester.tap(find.text('បន្ថែមទំនិញ'));
    await tester.pumpAndSettle();
    expect(result, '885');
  });
}

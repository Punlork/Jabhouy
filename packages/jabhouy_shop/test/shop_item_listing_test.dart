import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_shop/src/ui/widgets/shop_item_parts.dart';

void main() {
  group('formatRiel', () {
    test('groups thousands and uses the riel sign', () {
      expect(formatRiel(40000), '40,000 ៛');
      expect(formatRiel(12312321), '12,312,321 ៛');
      expect(formatRiel(999), '999 ៛');
      expect(formatRiel(1000), '1,000 ៛');
      expect(formatRiel(0), '0 ៛');
    });

    test('a missing price is a dash, never 0', () {
      expect(formatRiel(null), '—');
    });
  });

  group('product and variant names', () {
    // Names as the simulator's database stores them.
    test('split on the last " - ", with the pack size read separately', () {
      const pack = ShopItemModel(id: 72, name: 'Coca Cola - Pack x24');
      expect(pack.productName, 'Coca Cola');
      expect(pack.variantLabel, 'Pack');
      expect(pack.packAmount, 24);

      const long = ShopItemModel(id: 81, name: 'Test - 1231123213213213 x12');
      expect(long.productName, 'Test');
      expect(long.variantLabel, '1231123213213213');
    });

    test('a name with no label has an empty one', () {
      const plain = ShopItemModel(id: 1, name: 'Water');
      expect(plain.productName, 'Water');
      expect(plain.variantLabel, '');
    });
  });

  group('cards at phone width', () {
    // The worst of the real data, plus a category that cannot fit.
    const items = [
      ShopItemModel(
        id: 81,
        name: 'Test - 1231123213213213 x12',
        customerPrice: 123213,
      ),
      ShopItemModel(
        id: 83,
        name: 'AwknLKSNDjk1 - 123asdxsadaSD x12',
        customerPrice: 1231123213213213,
        category: CategoryItemModel(
          id: 4,
          name: 'A category name far too long for any card',
        ),
      ),
      ShopItemModel(
        id: 90,
        name: 'ភេសជ្ជៈត្រជាក់ឈ្មោះវែងណាស់សម្រាប់កាត',
      ),
    ];

    Future<void> pumpAt(
      WidgetTester tester,
      double width,
      Widget Function(ShopItemModel) card,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (final item in items)
                    SizedBox(width: width, child: card(item)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('the grid card never overflows at 170 wide', (tester) async {
      await pumpAt(
        tester,
        170,
        (item) => GridShopItemCard(item: item, onEdit: (_) {}),
      );

      expect(tester.takeException(), isNull);
      // The pack size survives however long the label is.
      expect(find.text(' · ×12'), findsNWidgets(2));
      expect(find.text('123,213 ៛'), findsOneWidget);
      expect(find.text('—'), findsOneWidget, reason: 'no price is a dash');
    });

    testWidgets('the list card never overflows at 360 wide', (tester) async {
      await pumpAt(
        tester,
        360,
        (item) => ShopItemCard(item: item, onEdit: (_) {}, onDelete: (_) {}),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('1231123213213213'), findsOneWidget);
    });

    testWidgets('an item with no label says which kind it is',
        (tester) async {
      await pumpAt(
        tester,
        170,
        (item) => GridShopItemCard(item: item, onEdit: (_) {}),
      );

      expect(find.text('Single'), findsOneWidget);
    });
  });
}

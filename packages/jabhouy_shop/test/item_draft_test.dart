import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';

PriceRowDraft _row({
  String unit = '',
  String packQty = '',
  String price = '',
  String wholesale = '',
  Currency currency = Currency.khr,
}) => PriceRowDraft(
  id: unit.isEmpty ? 'r' : unit,
  unit: unit,
  packQty: packQty,
  price: price,
  wholesale: wholesale,
  currency: currency,
);

ItemDraft _draft({String name = 'ទឹក', List<PriceRowDraft>? rows}) =>
    ItemDraft(id: 'i1', name: name, rows: rows ?? [_row(unit: 'ដប')]);

void main() {
  group('validate', () {
    test('a bottle and a 24-pack in one form is valid', () {
      final draft = _draft(
        rows: [
          _row(unit: 'ដប', price: '3,000'),
          _row(unit: 'កេះ', packQty: '24', price: '60,000'),
        ],
      );
      expect(draft.validate(), isEmpty);
    });

    test('an empty name blocks saving', () {
      expect(_draft(name: '  ').validate(), {
        'name': const FormProblem(ProblemKind.nameRequired),
      });
    });

    test('a decimal in riel is named as such', () {
      final draft = _draft(rows: [_row(unit: 'ដប', price: '3,000.5')]);
      expect(draft.validate(), {
        'ដប.price': const FormProblem(ProblemKind.rielDecimals),
      });
    });

    test('three decimals in dollars, or letters, are rejected', () {
      final draft = _draft(
        rows: [
          _row(unit: 'ដប', price: '7.505', currency: Currency.usd),
          _row(unit: 'កេះ', price: '7', wholesale: 'abc'),
        ],
      );
      expect(draft.validate(), {
        'ដប.price': const FormProblem(ProblemKind.usdDecimals),
        'កេះ.wholesale': const FormProblem(ProblemKind.invalidNumber),
      });
    });

    test('a count must be above 0; 1 and an empty count are fine', () {
      final draft = _draft(
        rows: [
          _row(unit: 'ដប', packQty: '1'),
          _row(unit: 'កេះ', packQty: '0'),
          _row(unit: 'បេ'),
        ],
      );
      expect(draft.validate(), {
        'កេះ.packQty': const FormProblem(ProblemKind.packQtyNotPositive),
      });
    });

    test('a name alone saves: quick add, priced later', () {
      final draft = _draft(rows: [_row()]);
      expect(draft.validate(), isEmpty);
      final item = draft.toItem();
      expect(item.prices, isEmpty);
      expect(item.hasMissingPrice, isTrue, reason: 'shows under the chip');
    });

    test('a barcode used by another item names that item', () {
      const draft = ItemDraft(
        id: 'i1',
        name: 'ទឹក',
        rows: [
          PriceRowDraft(
            id: 'r1',
            unit: 'ដប',
            currency: Currency.khr,
            barcode: '885',
          ),
        ],
      );
      expect(draft.validate(barcodeOwners: {'885': 'Coca-Cola'}), {
        'r1.barcode': const FormProblem(ProblemKind.barcodeUsed, 'Coca-Cola'),
      });
    });
  });

  group('toItem', () {
    test('an empty price saves as null, empty rows are dropped', () {
      final item = _draft(
        rows: [
          _row(unit: 'ដប', price: '3,000'),
          _row(unit: 'កេះ', packQty: '24'),
          _row(),
        ],
      ).toItem();
      expect(item.prices.map((p) => p.unit), ['ដប', 'កេះ']);
      expect(item.prices.first.price, 3000);
      expect(item.prices.last.price, isNull);
      expect(item.prices.last.packQty, 24);
    });

    test('dollars are stored as cents', () {
      final item = _draft(
        rows: [_row(unit: 'កេះ', price: '7.5', currency: Currency.usd)],
      ).toItem();
      expect(item.prices.single.selling, const Money(750, Currency.usd));
    });

    test('nicknames are trimmed and de-duplicated', () {
      final item = ItemDraft(
        id: 'i1',
        name: ' ទឹកអូគូលេនធំ ',
        nicknames: const ['ទឹកធំ', ' Kulen ', 'ទឹកធំ', ''],
        rows: [_row(unit: 'ដប')],
      ).toItem();
      expect(item.name, 'ទឹកអូគូលេនធំ');
      expect(item.nicknames, ['ទឹកធំ', 'Kulen']);
    });
  });

  group('suggestCategory', () {
    const categories = [
      ItemCategory(id: 'drinks', name: 'ភេសជ្ជៈ'),
      ItemCategory(id: 'rice', name: 'អង្ករ'),
      ItemCategory(id: 'milk', name: 'ទឹកដោះគោ'),
    ];

    test('a keyword in the name picks its category', () {
      expect(suggestCategory('អង្ករផ្កាម្លិះ', categories), 'rice');
      expect(suggestCategory('ទឹកអូគូលេនធំ', categories), 'drinks');
    });

    test('the longer keyword wins: milk is not a drink', () {
      expect(suggestCategory('ទឹកដោះគោ Dutch Mill', categories), 'milk');
    });

    test('no keyword, or a category the shop lacks, suggests nothing', () {
      expect(suggestCategory('Sunlight', categories), isNull);
      expect(suggestCategory('ប្រេងឆា', categories), isNull);
    });
  });
}

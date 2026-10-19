import 'package:equatable/equatable.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/ui/widgets/whole_number_input.dart';

enum ProblemKind {
  nameRequired,
  rielDecimals,
  usdDecimals,
  invalidNumber,
  packQtyOverOne,
  barcodeUsed,
  noPriceRow,
}

/// Why one field cannot save; [itemName] names the other Item for
/// [ProblemKind.barcodeUsed].
class FormProblem extends Equatable {
  const FormProblem(this.kind, [this.itemName]);

  final ProblemKind kind;
  final String? itemName;

  @override
  List<Object?> get props => [kind, itemName];
}

/// One price row as typed: text, so a typo can be named instead of lost.
class PriceRowDraft {
  const PriceRowDraft({
    required this.id,
    required this.currency,
    this.unit = '',
    this.packQty = '',
    this.price = '',
    this.wholesale = '',
    this.cost = '',
    this.barcode,
  });

  factory PriceRowDraft.from(PriceOption option) => PriceRowDraft(
    id: option.id,
    currency: option.currency,
    unit: option.unit,
    packQty: option.packQty?.toString() ?? '',
    price: option.selling?.formatNumber() ?? '',
    wholesale: option.wholesaleMoney?.formatNumber() ?? '',
    cost: option.costMoney?.formatNumber() ?? '',
    barcode: option.barcode,
  );

  final String id;
  final Currency currency;
  final String unit;
  final String packQty;
  final String price;
  final String wholesale;
  final String cost;
  final String? barcode;

  bool get isEmpty => [
    unit,
    packQty,
    price,
    wholesale,
    cost,
    barcode ?? '',
  ].every((text) => text.trim().isEmpty);
}

/// The add/edit item form's content, checked and turned into an [Item].
class ItemDraft {
  const ItemDraft({
    required this.id,
    required this.name,
    required this.rows,
    this.nicknames = const [],
    this.categoryId,
    this.note = '',
  });

  final String id;
  final String name;
  final List<String> nicknames;
  final String? categoryId;
  final String note;
  final List<PriceRowDraft> rows;

  Iterable<PriceRowDraft> get _usedRows => rows.where((r) => !r.isEmpty);

  /// Problems keyed by field: `name`, `rows`, or `<rowId>.<field>`.
  /// [barcodeOwners] maps a barcode to the other Item already using it.
  Map<String, FormProblem> validate({
    Map<String, String> barcodeOwners = const {},
  }) {
    final problems = <String, FormProblem>{
      if (name.trim().isEmpty) 'name': const FormProblem(ProblemKind.nameRequired),
      if (_usedRows.isEmpty) 'rows': const FormProblem(ProblemKind.noPriceRow),
    };
    for (final row in _usedRows) {
      final pack = row.packQty.trim();
      if (pack.isNotEmpty) {
        final qty = parseWholeNumber(pack);
        final kind = switch (qty) {
          null => ProblemKind.invalidNumber,
          <= 1 => ProblemKind.packQtyOverOne,
          _ => null,
        };
        if (kind != null) problems['${row.id}.packQty'] = FormProblem(kind);
      }
      for (final (field, text) in [
        ('price', row.price),
        ('wholesale', row.wholesale),
        ('cost', row.cost),
      ]) {
        final kind = _moneyProblem(text, row.currency);
        if (kind != null) problems['${row.id}.$field'] = FormProblem(kind);
      }
      final owner = barcodeOwners[row.barcode];
      if (owner != null) {
        problems['${row.id}.barcode'] = FormProblem(
          ProblemKind.barcodeUsed,
          owner,
        );
      }
    }
    return problems;
  }

  /// Call after [validate] is empty. Empty rows are dropped; an empty
  /// price is null, never 0.
  Item toItem() {
    final names = <String>{
      for (final n in nicknames)
        if (n.trim().isNotEmpty) n.trim(),
    };
    return Item(
      id: id,
      name: name.trim(),
      nicknames: names.toList(),
      categoryId: categoryId,
      note: note.trim().isEmpty ? null : note.trim(),
      prices: [
        for (final (i, row) in _usedRows.indexed)
          PriceOption(
            id: row.id,
            unit: row.unit.trim(),
            packQty: parseWholeNumber(row.packQty),
            barcode: row.barcode,
            currency: row.currency,
            price: Money.tryParse(row.price, row.currency)?.amount,
            wholesale: Money.tryParse(row.wholesale, row.currency)?.amount,
            cost: Money.tryParse(row.cost, row.currency)?.amount,
            sortOrder: i,
          ),
      ],
    );
  }

  static ProblemKind? _moneyProblem(String text, Currency currency) {
    final clean = text.replaceAll(',', '').trim();
    if (clean.isEmpty || Money.tryParse(clean, currency) != null) return null;
    final decimal = RegExp(r'^\d*\.\d+$').hasMatch(clean);
    return switch (currency) {
      Currency.khr when decimal => ProblemKind.rielDecimals,
      Currency.usd when decimal => ProblemKind.usdDecimals,
      _ => ProblemKind.invalidNumber,
    };
  }
}

/// Keyword → category name, longest keyword first so `ទឹកដោះគោ` (milk)
/// beats `ទឹក` (drinks).
/// shortcut: fixed to the plan's starter names; §9 may rename them, and
/// a renamed category simply stops being suggested.
const _keywords = [
  ('ទឹកដោះគោ', 'ទឹកដោះគោ'),
  ('ស្រាបៀរ', 'ស្រា/ស្រាបៀរ'),
  ('ថ្នាំដុសធ្មេញ', 'សាប៊ូ/អនាម័យ'),
  ('សាប៊ូ', 'សាប៊ូ/អនាម័យ'),
  ('អង្ករ', 'អង្ករ'),
  ('ប្រេង', 'ប្រេងឆា'),
  ('បារី', 'បារី'),
  ('ស្រា', 'ស្រា/ស្រាបៀរ'),
  ('beer', 'ស្រា/ស្រាបៀរ'),
  ('ទឹក', 'ភេសជ្ជៈ'),
  ('មី', 'មី'),
];

/// The id of the category [name] suggests, or null.
String? suggestCategory(String name, List<ItemCategory> categories) {
  final lower = name.toLowerCase();
  for (final (keyword, categoryName) in _keywords) {
    if (!lower.contains(keyword)) continue;
    for (final category in categories) {
      if (category.name == categoryName) return category.id;
    }
  }
  return null;
}

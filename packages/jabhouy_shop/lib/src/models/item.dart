import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

part 'item.g.dart';

/// One way an Item is sold: a unit, an optional pack size, and its prices
/// in one currency. A null price means "no price yet", never 0.
class PriceOption {
  const PriceOption({
    required this.id,
    required this.unit,
    required this.currency,
    this.packQty,
    this.barcode,
    this.price,
    this.wholesale,
    this.cost,
    this.sortOrder = 0,
  });

  final String id;
  final String unit;
  final int? packQty;
  final String? barcode;
  final Currency currency;

  /// Whole riel or cents.
  final int? price;
  final int? wholesale;
  final int? cost;
  final int sortOrder;

  Money? get selling => _money(price);
  Money? get wholesaleMoney => _money(wholesale);
  Money? get costMoney => _money(cost);

  Money? _money(int? amount) => amount == null ? null : Money(amount, currency);
}

/// A thing the Shop sells, with one or more [PriceOption]s.
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.prices,
    this.nicknames = const [],
    this.categoryId,
    this.photoUrl,
    this.note,
    this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final String name;

  /// Other names people use for it; search matches them too.
  final List<String> nicknames;
  final String? categoryId;
  final String? photoUrl;
  final String? note;
  final List<PriceOption> prices;
  final DateTime? updatedAt;
  final String? updatedBy;

  /// True with no Price option yet, or any without a selling price.
  bool get hasMissingPrice =>
      prices.isEmpty || prices.any((p) => p.price == null);
}

/// The Shop's price and currency settings (canvas ១២ក).
@CopyWith()
class PriceSettings {
  const PriceSettings({
    this.useWholesale = false,
    this.useCost = true,
    this.currency = Currency.khr,
    this.khrPerUsd = 4000,
    this.showConverted = true,
    this.rateUpdatedAt,
    this.rateUpdatedBy,
  });

  final bool useWholesale;
  final bool useCost;

  /// Default currency for a new price row.
  final Currency currency;
  final int khrPerUsd;

  /// Shows the `≈` other-currency line under prices.
  final bool showConverted;

  /// When and by whom [khrPerUsd] last changed.
  final DateTime? rateUpdatedAt;
  final String? rateUpdatedBy;
}

/// A unit name suggested as a chip for Items in an [ItemCategory].
class CategoryUnit {
  const CategoryUnit({required this.unit, this.hidden = false});

  final String unit;
  final bool hidden;
}

/// A group of Items, with the units its Items are usually sold in.
/// (`Category` is taken by the old table's row class until schema 10.)
class ItemCategory {
  const ItemCategory({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.hidden = false,
    this.units = const [],
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool hidden;
  final List<CategoryUnit> units;
}

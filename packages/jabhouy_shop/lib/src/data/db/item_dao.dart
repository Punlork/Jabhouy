import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/src/models/item.dart';

/// Drift queries for redesign Items, Price options, categories and units.
/// Every read is scoped to one Shop and skips deleted rows.
class ItemDao {
  ItemDao(this._db);

  final AppDatabase _db;

  Stream<List<Item>> watchItems(
    String shopId, {
    String search = '',
    String? categoryId,
  }) {
    final query =
        _db.select(_db.itemTable).join([
            leftOuterJoin(
              _db.itemPriceTable,
              _db.itemPriceTable.itemId.equalsExp(_db.itemTable.id),
            ),
          ])
          ..where(
            _db.itemTable.shopId.equals(shopId) &
                _db.itemTable.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(_db.itemTable.name),
            OrderingTerm.asc(_db.itemPriceTable.sortOrder),
          ]);
    if (search.isNotEmpty) {
      query.where(_db.itemTable.name.like('%$search%'));
    }
    if (categoryId != null) {
      query.where(_db.itemTable.categoryId.equals(categoryId));
    }
    return query.watch().map((rows) {
      final items = <String, (ItemRow, List<PriceOption>)>{};
      for (final row in rows) {
        final item = row.readTable(_db.itemTable);
        final entry = items.putIfAbsent(item.id, () => (item, []));
        final price = row.readTableOrNull(_db.itemPriceTable);
        if (price != null) entry.$2.add(_option(price));
      }
      return [for (final (row, prices) in items.values) _item(row, prices)];
    });
  }

  /// Writes the Item and replaces its Price options; adds new units to
  /// the Item's category. One transaction.
  Future<void> saveItem(
    String shopId,
    Item item, {
    required DateTime now,
    String? userId,
  }) {
    return _db.transaction(() async {
      await _db
          .into(_db.itemTable)
          .insertOnConflictUpdate(
            ItemTableCompanion.insert(
              id: item.id,
              shopId: shopId,
              name: item.name,
              nicknames: Value(jsonEncode(item.nicknames)),
              categoryId: Value(item.categoryId),
              photoUrl: Value(item.photoUrl),
              note: Value(item.note),
              updatedAt: Value(now),
              updatedBy: Value(userId),
              deletedAt: const Value(null),
            ),
          );
      await (_db.delete(
        _db.itemPriceTable,
      )..where((p) => p.itemId.equals(item.id))).go();
      for (final (i, option) in item.prices.indexed) {
        await _db
            .into(_db.itemPriceTable)
            .insert(
              ItemPriceTableCompanion.insert(
                id: option.id,
                itemId: item.id,
                unit: option.unit,
                packQty: Value(option.packQty),
                barcode: Value(option.barcode),
                currency: option.currency.name.toUpperCase(),
                price: Value(option.price),
                wholesale: Value(option.wholesale),
                cost: Value(option.cost),
                sortOrder: Value(i),
              ),
            );
      }
      final categoryId = item.categoryId;
      if (categoryId != null) {
        for (final option in item.prices) {
          if (option.unit.trim().isEmpty) continue;
          await _db
              .into(_db.categoryUnitTable)
              .insert(
                CategoryUnitTableCompanion.insert(
                  categoryId: categoryId,
                  unit: option.unit.trim(),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
    });
  }

  Future<void> markItemDeleted(String id, DateTime now, String? userId) {
    return (_db.update(_db.itemTable)..where((i) => i.id.equals(id))).write(
      ItemTableCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        updatedBy: Value(userId),
      ),
    );
  }

  /// Barcode → name of another live Item in [shopId] using it.
  Future<Map<String, String>> barcodeOwners(
    String shopId,
    Iterable<String> barcodes, {
    required String exceptItemId,
  }) async {
    final query =
        _db.select(_db.itemPriceTable).join([
          innerJoin(
            _db.itemTable,
            _db.itemTable.id.equalsExp(_db.itemPriceTable.itemId),
          ),
        ])..where(
          _db.itemTable.shopId.equals(shopId) &
              _db.itemTable.deletedAt.isNull() &
              _db.itemTable.id.equals(exceptItemId).not() &
              _db.itemPriceTable.barcode.isIn(barcodes),
        );
    return {
      for (final row in await query.get())
        row.readTable(_db.itemPriceTable).barcode!: row
            .readTable(_db.itemTable)
            .name,
    };
  }

  /// Id of another live Item in [shopId] with this name, ignoring case
  /// and outer spaces.
  Future<String?> itemNamed(
    String shopId,
    String name, {
    required String exceptItemId,
  }) async {
    final row =
        await (_db.select(_db.itemTable)
              ..where(
                (i) =>
                    i.shopId.equals(shopId) &
                    i.deletedAt.isNull() &
                    i.id.equals(exceptItemId).not() &
                    i.name.trim().lower().equals(name.trim().toLowerCase()),
              )
              ..limit(1))
            .getSingleOrNull();
    return row?.id;
  }

  /// Category of the newest saved Item in [shopId] that has one.
  Future<String?> lastUsedCategoryId(String shopId) async {
    final row =
        await (_db.select(_db.itemTable)
              ..where(
                (i) =>
                    i.shopId.equals(shopId) &
                    i.deletedAt.isNull() &
                    i.categoryId.isNotNull(),
              )
              ..orderBy([(i) => OrderingTerm.desc(i.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.categoryId;
  }

  /// The Shop's price settings; the table's defaults until a row exists.
  Future<PriceSettings> priceSettings(String shopId) async {
    final row = await (_db.select(
      _db.shopSettingsTable,
    )..where((s) => s.shopId.equals(shopId))).getSingleOrNull();
    if (row == null) return const PriceSettings();
    return PriceSettings(
      useWholesale: row.useWholesalePrice,
      useCost: row.useCostPrice,
      currency: Currency.values.byName(row.defaultCurrency.toLowerCase()),
      khrPerUsd: row.khrPerUsd,
    );
  }

  Stream<List<ItemCategory>> watchCategories(String shopId) {
    final query =
        _db.select(_db.categoryTable).join([
            leftOuterJoin(
              _db.categoryUnitTable,
              _db.categoryUnitTable.categoryId.equalsExp(_db.categoryTable.id),
            ),
          ])
          ..where(
            _db.categoryTable.shopId.equals(shopId) &
                _db.categoryTable.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(_db.categoryTable.sortOrder),
            OrderingTerm.asc(_db.categoryTable.name),
          ]);
    return query.watch().map((rows) {
      final categories = <String, (CategoryRow, List<CategoryUnit>)>{};
      for (final row in rows) {
        final category = row.readTable(_db.categoryTable);
        final entry = categories.putIfAbsent(category.id, () => (category, []));
        final unit = row.readTableOrNull(_db.categoryUnitTable);
        if (unit != null) {
          entry.$2.add(CategoryUnit(unit: unit.unit, hidden: unit.hidden));
        }
      }
      return [
        for (final (row, units) in categories.values)
          ItemCategory(
            id: row.id,
            name: row.name,
            sortOrder: row.sortOrder,
            hidden: row.hidden,
            units: units,
          ),
      ];
    });
  }

  /// Writes the category; its units merge: named ones are added or have
  /// `hidden` updated, others are left alone (decision 25).
  Future<void> saveCategory(
    String shopId,
    ItemCategory category, {
    required DateTime now,
    String? userId,
  }) {
    return _db.transaction(() async {
      await _db
          .into(_db.categoryTable)
          .insertOnConflictUpdate(
            CategoryTableCompanion.insert(
              id: category.id,
              shopId: shopId,
              name: category.name,
              sortOrder: Value(category.sortOrder),
              hidden: Value(category.hidden),
              updatedAt: Value(now),
              updatedBy: Value(userId),
              deletedAt: const Value(null),
            ),
          );
      for (final unit in category.units) {
        await _db
            .into(_db.categoryUnitTable)
            .insertOnConflictUpdate(
              CategoryUnitTableCompanion.insert(
                categoryId: category.id,
                unit: unit.unit,
                hidden: Value(unit.hidden),
              ),
            );
      }
    });
  }

  /// Visible units of [categoryId], most used first (decision 13).
  Future<List<String>> unitsByUse(String categoryId) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT cu.unit AS unit, COUNT(ip.id) AS uses
      FROM category_unit cu
      LEFT JOIN item i
        ON i.category_id = cu.category_id AND i.deleted_at IS NULL
      LEFT JOIN item_price ip
        ON ip.item_id = i.id AND ip.unit = cu.unit
      WHERE cu.category_id = ? AND cu.hidden = 0
      GROUP BY cu.unit
      ORDER BY uses DESC, cu.unit ASC
      ''',
          variables: [Variable.withString(categoryId)],
          readsFrom: {_db.categoryUnitTable, _db.itemTable, _db.itemPriceTable},
        )
        .get();
    return [for (final row in rows) row.read<String>('unit')];
  }

  static Item _item(ItemRow row, List<PriceOption> prices) => Item(
    id: row.id,
    name: row.name,
    nicknames: (jsonDecode(row.nicknames) as List).cast<String>(),
    categoryId: row.categoryId,
    photoUrl: row.photoUrl,
    note: row.note,
    prices: prices,
    updatedAt: row.updatedAt,
    updatedBy: row.updatedBy,
  );

  static PriceOption _option(ItemPriceRow row) => PriceOption(
    id: row.id,
    unit: row.unit,
    packQty: row.packQty,
    barcode: row.barcode,
    currency: Currency.values.byName(row.currency.toLowerCase()),
    price: row.price,
    wholesale: row.wholesale,
    cost: row.cost,
    sortOrder: row.sortOrder,
  );
}

import 'package:drift/drift.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';

/// Every Drift statement the shop feature issues, and the only place that
/// knows `ShopItems` is a table rather than a list of [ShopItemModel].
///
/// This is a plain class, not a `@DriftAccessor`. The schema lives in
/// `jabhouy_core` and the app package currently generates nothing — `find
/// lib -name '*.g.dart'` is empty. A `@DriftAccessor` here would put a
/// generated mixin in the app that references tables from another workspace
/// member, which is the cross-package codegen the restructure doc flags as
/// the phase 5 risk. It would buy the `select()`/`update()` shorthand and
/// nothing else, so it can wait until phase 5 decides that question on
/// purpose.
class ShopDao {
  const ShopDao(this._db);

  final AppDatabase _db;

  Stream<List<ShopItemModel>> watchItems({
    String searchQuery = '',
    CategoryItemModel? categoryFilter,
  }) {
    final query = _db.select(_db.shopItems).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.shopItems.categoryId) &
            _db.categories.isDeleted.equals(false),
      ),
    ])
      ..where(_db.shopItems.isDeleted.equals(false));

    if (searchQuery.isNotEmpty) {
      query.where(
        _db.shopItems.name.contains(searchQuery) |
            _db.shopItems.note.contains(searchQuery),
      );
    }

    if (categoryFilter != null) {
      query.where(_db.shopItems.categoryId.equals(categoryFilter.id));
    }

    query.orderBy([
      OrderingTerm(
        expression: _db.shopItems.updatedAt,
        mode: OrderingMode.desc,
      ),
      OrderingTerm(
        expression: _db.shopItems.createdAt,
        mode: OrderingMode.desc,
      ),
    ]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => _toModel(
                  row.readTable(_db.shopItems),
                  row.readTableOrNull(_db.categories),
                ),
              )
              .toList(),
        );
  }

  Future<bool> hasCachedItems({
    String searchQuery = '',
    CategoryItemModel? categoryFilter,
  }) async {
    final query = _db.select(_db.shopItems)
      ..where((t) => t.isDeleted.equals(false));

    if (searchQuery.isNotEmpty) {
      query.where(
        (t) => t.name.contains(searchQuery) | t.note.contains(searchQuery),
      );
    }

    if (categoryFilter != null) {
      query.where((t) => t.categoryId.equals(categoryFilter.id));
    }

    query.limit(1);
    return (await query.get()).isNotEmpty;
  }

  Future<ShopItemModel?> findById(int id) async {
    final row = await (_db.select(_db.shopItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// Replaces the local cache for a page pulled from the server.
  /// Writes one page of server rows, as the old per-load refresh does.
  /// A page is never the whole list, so it deletes nothing.
  Future<void> cacheServerItems(List<ShopItemModel> items) =>
      reconcileServerItems(items, complete: false);

  /// Writes server rows, skipping any row with a queued job.
  ///
  /// Writing over those would put the server's older copy where the
  /// seller's unsent edit was, and the queued job, which re-reads the row,
  /// would then send that older copy. A queued delete would come back.
  ///
  /// With [complete], [items] is everything the server holds, so a row it
  /// did not return was deleted there and goes here too — unless it has a
  /// queued job, or a negative id, which means the server never had it.
  Future<void> reconcileServerItems(
    List<ShopItemModel> items, {
    required bool complete,
  }) {
    return _db.transaction(() async {
      // Read inside the transaction, so an edit cannot land between the
      // check and the write.
      final queued = await _db.queuedLocalIds(SyncEntityType.shopItem);
      await _db.batch((batch) {
        batch.insertAll(
          _db.shopItems,
          items
              .where((i) => !queued.contains('${i.id}'))
              .map((i) => _companion(i, SyncStatus.synced)),
          mode: InsertMode.insertOrReplace,
        );
      });
      if (!complete) return;

      final onServer = items.map((i) => i.id).toList();
      final keep = queued.map(int.tryParse).whereType<int>().toList();
      await (_db.shopItems.delete()
            ..where(
              (t) =>
                  t.id.isBiggerThanValue(0) &
                  t.id.isNotIn(onServer) &
                  t.id.isNotIn(keep),
            ))
          .go();
    });
  }

  Future<void> insertPending(ShopItemModel item) {
    return _db.into(_db.shopItems).insert(
          _companion(item, SyncStatus.pending),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> replace(ShopItemModel item, SyncStatus status) {
    return _db.update(_db.shopItems).replace(_row(item, status));
  }

  Future<void> markDeletedPending(int id) {
    return (_db.update(_db.shopItems)..where((t) => t.id.equals(id))).write(
      const ShopItemsCompanion(
        isDeleted: Value(true),
        syncStatus: Value(SyncStatus.pending),
      ),
    );
  }

  Future<void> markFailed(int id) {
    return (_db.update(_db.shopItems)..where((t) => t.id.equals(id))).write(
      const ShopItemsCompanion(syncStatus: Value(SyncStatus.failed)),
    );
  }

  Future<void> purge(int id) {
    return (_db.delete(_db.shopItems)..where((t) => t.id.equals(id))).go();
  }

  /// Swaps a locally-minted negative id for the id the server assigned.
  ///
  /// The delete and the insert run in one transaction. They used to be two
  /// statements, so a crash between them left the item on neither the phone
  /// nor the pending queue.
  Future<void> reconcileCreated({
    required int localId,
    required ShopItemModel serverItem,
  }) {
    return _db.transaction(() async {
      await purge(localId);
      await _db.into(_db.shopItems).insert(
            _companion(serverItem, SyncStatus.synced),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  ShopItemModel _toModel(ShopItem item, [Category? category]) {
    return ShopItemModel(
      id: item.id,
      name: item.name,
      defaultPrice: item.defaultPrice,
      customerPrice: item.customerPrice,
      sellerPrice: item.sellerPrice,
      note: item.note,
      imageUrl: item.imageUrl,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      syncStatus: item.syncStatus,
      isDeleted: item.isDeleted,
      category: category?.let(
            (value) => CategoryItemModel(
              id: value.id,
              name: value.name,
              syncStatus: value.syncStatus,
              isDeleted: value.isDeleted,
            ),
          ) ??
          (item.categoryId == null
              ? null
              : CategoryItemModel(id: item.categoryId!, name: '')),
    );
  }

  ShopItemsCompanion _companion(ShopItemModel item, SyncStatus status) {
    return ShopItemsCompanion.insert(
      id: Value(item.id),
      name: item.name,
      defaultPrice: Value(item.defaultPrice),
      customerPrice: Value(item.customerPrice),
      sellerPrice: Value(item.sellerPrice),
      note: Value(item.note),
      imageUrl: Value(item.imageUrl),
      categoryId: Value(item.category?.id),
      createdAt: Value(item.createdAt ?? DateTime.now()),
      updatedAt: Value(item.updatedAt ?? DateTime.now()),
      syncStatus: Value(status),
      isDeleted: Value(item.isDeleted),
    );
  }

  ShopItem _row(ShopItemModel item, SyncStatus status) {
    return ShopItem(
      id: item.id,
      name: item.name,
      defaultPrice: item.defaultPrice,
      customerPrice: item.customerPrice,
      sellerPrice: item.sellerPrice,
      note: item.note,
      imageUrl: item.imageUrl,
      categoryId: item.category?.id,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      syncStatus: status,
      isDeleted: item.isDeleted,
    );
  }
}

import 'package:drift/drift.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';

/// Every Drift statement the category feature issues.
///
/// A plain class rather than a `@DriftAccessor`, for the reason given on
/// [ShopDao].
class CategoryDao {
  const CategoryDao(this._db);

  final AppDatabase _db;

  Stream<List<CategoryItemModel>> watchCategories() {
    return (_db.select(_db.categories)
          ..where((t) => t.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  Future<CategoryItemModel?> findById(int id) async {
    final row = await (_db.select(_db.categories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// Writes one page of server rows, as the old per-load refresh does.
  /// A page is never the whole list, so it deletes nothing.
  Future<void> cacheServerCategories(List<CategoryItemModel> categories) =>
      reconcileServerCategories(categories, complete: false);

  /// Writes server rows, skipping any row with a queued job.
  ///
  /// Writing over those would put the server's older copy where the
  /// seller's unsent edit was, and the queued job, which re-reads the row,
  /// would then send that older copy. A queued delete would come back.
  ///
  /// With [complete], [categories] is everything the server holds, so a row it
  /// did not return was deleted there and goes here too — unless it has a
  /// queued job, or a negative id, which means the server never had it.
  Future<void> reconcileServerCategories(
    List<CategoryItemModel> categories, {
    required bool complete,
  }) {
    return _db.transaction(() async {
      // Read inside the transaction, so an edit cannot land between the
      // check and the write.
      final queued = await _db.queuedLocalIds(SyncEntityType.category);
      await _db.batch((batch) {
        batch.insertAll(
          _db.categories,
          categories
              .where((c) => !queued.contains('${c.id}'))
              .map((c) => _companion(c, SyncStatus.synced)),
          mode: InsertMode.insertOrReplace,
        );
      });
      if (!complete) return;

      final onServer = categories.map((c) => c.id).toList();
      final keep = queued.map(int.tryParse).whereType<int>().toList();
      await (_db.categories.delete()
            ..where(
              (t) =>
                  t.id.isBiggerThanValue(0) &
                  t.id.isNotIn(onServer) &
                  t.id.isNotIn(keep),
            ))
          .go();
    });
  }

  Future<void> insertPending(CategoryItemModel category) {
    return _db.into(_db.categories).insert(
          _companion(category, SyncStatus.pending),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> replace(CategoryItemModel category, SyncStatus status) {
    return _db.update(_db.categories).replace(
          Category(
            id: category.id,
            name: category.name,
            syncStatus: status,
            isDeleted: category.isDeleted,
          ),
        );
  }

  Future<void> markDeletedPending(int id) {
    return (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      const CategoriesCompanion(
        isDeleted: Value(true),
        syncStatus: Value(SyncStatus.pending),
      ),
    );
  }

  Future<void> markFailed(int id) {
    return (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      const CategoriesCompanion(syncStatus: Value(SyncStatus.failed)),
    );
  }

  Future<void> purge(int id) {
    return (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }

  /// Swaps a locally-minted negative id for the one the server assigned,
  /// and repoints every shop item that referenced the local id.
  ///
  /// The repoint is the half `ShopDao.reconcileCreated` cannot do: a
  /// category is the only table anything else references, so it is the
  /// only reconciliation that has to fix a foreign key. All of it is one
  /// transaction — a crash partway through would otherwise leave items
  /// pointing at a category id that no longer exists.
  Future<void> reconcileCreated({
    required int localId,
    required CategoryItemModel serverCategory,
  }) {
    return _db.transaction(() async {
      await _db.into(_db.categories).insert(
            _companion(serverCategory, SyncStatus.synced),
            mode: InsertMode.insertOrReplace,
          );
      await (_db.update(_db.shopItems)
            ..where((t) => t.categoryId.equals(localId)))
          .write(ShopItemsCompanion(categoryId: Value(serverCategory.id)));
      await purge(localId);
    });
  }

  CategoryItemModel _toModel(Category row) {
    return CategoryItemModel(
      id: row.id,
      name: row.name,
      syncStatus: row.syncStatus,
      isDeleted: row.isDeleted,
    );
  }

  CategoriesCompanion _companion(CategoryItemModel c, SyncStatus status) {
    return CategoriesCompanion.insert(
      id: Value(c.id),
      name: c.name,
      syncStatus: Value(status),
      isDeleted: Value(c.isDeleted),
    );
  }
}

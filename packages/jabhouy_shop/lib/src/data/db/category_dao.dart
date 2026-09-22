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

  Future<void> cacheServerCategories(List<CategoryItemModel> categories) {
    return _db.batch((batch) {
      batch.insertAll(
        _db.categories,
        categories.map((c) => _companion(c, SyncStatus.synced)),
        mode: InsertMode.insertOrReplace,
      );
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

import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/src/data/db/item_dao.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Plan §3.2's starter categories and their usual units.
/// shortcut: names await the shop families (§9); the server seeds real
/// Shops (Phase 2b), so only the stand-in Shop uses this list.
const starterCategories = [
  ('ភេសជ្ជៈ', ['ដប', 'កំប៉ុង', 'កេះ']),
  ('អង្ករ', ['គីឡូ', 'បេ']),
  ('មី', ['កញ្ចប់', 'កេស']),
  ('សាប៊ូ/អនាម័យ', ['ដុំ', 'ដប', 'កញ្ចប់']),
  ('នំ/ចំណី', <String>[]),
  ('ទឹកដោះគោ', <String>[]),
  ('ស្រា/ស្រាបៀរ', <String>[]),
  ('គ្រឿងទេស', <String>[]),
  ('ប្រេងឆា', <String>[]),
  ('បារី', <String>[]),
  ('ផ្សេងៗ', <String>[]),
];

/// Items, their Price options, categories and units for the Current Shop.
/// Writes go to Drift first, then the outbox, then a sync is requested
/// when online. The stand-in Shop (`ShopScope.syncs` false) queues nothing.
class ItemRepository {
  ItemRepository(
    this._dao,
    this._scope,
    this._engine,
    this._connectivity, {
    this._clock = DateTime.now,
  });

  final ItemDao _dao;
  final ShopScope _scope;
  final SyncEngine _engine;
  final ConnectivityService _connectivity;
  final DateTime Function() _clock;

  String get _shopId => _scope.shopId!;

  Stream<List<Item>> watchItems({
    String search = '',
    String? categoryId,
    bool missingOnly = false,
  }) {
    final items = _dao.watchItems(
      _shopId,
      search: search,
      categoryId: categoryId,
    );
    return missingOnly
        ? items.map((all) => [...all.where((i) => i.hasMissingPrice)])
        : items;
  }

  /// Items with any Price option still missing its selling price.
  Stream<int> watchMissingPriceCount() => _dao
      .watchItems(_shopId)
      .map((all) => all.where((i) => i.hasMissingPrice).length);

  Future<Result<Item>> saveItem(Item item) async {
    final now = _clock();
    await _dao.saveItem(_shopId, item, now: now, userId: _scope.userId);
    await _queue(SyncEntityType.item, item.id, SyncOperation.update, now);
    return Ok(item);
  }

  Future<Result<void>> deleteItem(String id) async {
    final now = _clock();
    await _dao.markItemDeleted(id, now, _scope.userId);
    await _queue(SyncEntityType.item, id, SyncOperation.delete, now);
    return const Ok(null);
  }

  Stream<List<ItemCategory>> watchCategories() => _dao.watchCategories(_shopId);

  Future<Result<ItemCategory>> saveCategory(ItemCategory category) async {
    final now = _clock();
    await _dao.saveCategory(_shopId, category, now: now, userId: _scope.userId);
    await _queue(
      SyncEntityType.itemCategory,
      category.id,
      SyncOperation.update,
      now,
    );
    return Ok(category);
  }

  Future<Map<String, String>> barcodeOwners(
    Iterable<String> barcodes, {
    required String exceptItemId,
  }) => _dao.barcodeOwners(_shopId, barcodes, exceptItemId: exceptItemId);

  Future<String?> itemNamed(String name, {required String exceptItemId}) =>
      _dao.itemNamed(_shopId, name, exceptItemId: exceptItemId);

  Future<String?> lastUsedCategoryId() => _dao.lastUsedCategoryId(_shopId);

  Future<PriceSettings> priceSettings() => _dao.priceSettings(_shopId);

  Future<String?> memberName(String userId) =>
      _dao.memberName(_shopId, userId);

  /// Gives the stand-in Shop the starter categories when it has none. A
  /// server Shop is seeded by the server, so it is left alone.
  Future<void> seedStarterCategories() async {
    if (_scope.syncs) return;
    if ((await _dao.watchCategories(_shopId).first).isNotEmpty) return;
    final now = _clock();
    for (final (i, (name, units)) in starterCategories.indexed) {
      await _dao.saveCategory(
        _shopId,
        ItemCategory(
          id: newId(),
          name: name,
          sortOrder: i,
          units: [for (final unit in units) CategoryUnit(unit: unit)],
        ),
        now: now,
        userId: _scope.userId,
      );
    }
  }

  /// Visible units for the form's chips, most used first.
  Future<List<String>> unitsFor(String categoryId) =>
      _dao.unitsByUse(categoryId);

  Future<void> _queue(
    SyncEntityType type,
    String id,
    SyncOperation operation,
    DateTime now,
  ) async {
    if (!_scope.syncs) return;
    await _engine.enqueue(
      entityType: type,
      localId: id,
      operation: operation,
      idempotencyKey: '${type.name}:$id:${now.microsecondsSinceEpoch}',
    );
    if (await _connectivity.isOnline) _engine.requestSync();
  }
}

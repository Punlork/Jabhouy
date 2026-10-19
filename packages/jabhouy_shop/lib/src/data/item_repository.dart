import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/src/data/db/item_dao.dart';
import 'package:jabhouy_shop/src/logic/item_search.dart';
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

  /// A [search] ranks in memory (decision 42): best match first.
  Stream<List<Item>> watchItems({
    String search = '',
    String? categoryId,
    bool missingOnly = false,
  }) {
    final query = normalizeSearch(search);
    return _dao.watchItems(_shopId, categoryId: categoryId).map((all) {
      final items = missingOnly
          ? [...all.where((i) => i.hasMissingPrice)]
          : all;
      if (query.isEmpty) return items;
      return [for (final hit in searchItems(items, query)) hit.item];
    });
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

  /// Remembers an opened Item on this phone only; never synced (decision 46).
  Future<void> recordView(String itemId) =>
      _dao.recordView(_shopId, itemId, _clock());

  /// The last 10 opened Items, newest first, for RecentPills.
  Stream<List<Item>> watchRecentItems() => _dao.watchRecentItems(_shopId);

  /// Pull to refresh: sends queued changes now.
  /// shortcut: pushes only; pulling Items from the server lands with
  /// issue 11 (`/shops/:id/changes`).
  Future<void> pullLatest() async {
    if (!_scope.syncs || !await _connectivity.isOnline) return;
    await _engine.drain();
  }

  Stream<List<ItemCategory>> watchCategories() => _dao.watchCategories(_shopId);

  /// Owner and editor; a viewer only reads (the server enforces it too).
  Future<Result<ItemCategory>> saveCategory(ItemCategory category) async {
    if (_scope.role == MemberRole.viewer) return const Err(_viewerReadOnly);
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

  /// Gives every category in [ids] its place in the list as `sortOrder`.
  Future<Result<void>> reorderCategories(List<String> ids) async {
    if (_scope.role == MemberRole.viewer) return const Err(_viewerReadOnly);
    final now = _clock();
    await _dao.reorderCategories(ids, now: now, userId: _scope.userId);
    for (final id in ids) {
      await _queue(SyncEntityType.itemCategory, id, SyncOperation.update, now);
    }
    return const Ok(null);
  }

  static const _viewerReadOnly = AppException('A viewer cannot edit.');

  Future<Map<String, String>> barcodeOwners(
    Iterable<String> barcodes, {
    required String exceptItemId,
  }) => _dao.barcodeOwners(_shopId, barcodes, exceptItemId: exceptItemId);

  Future<String?> itemNamed(String name, {required String exceptItemId}) =>
      _dao.itemNamed(_shopId, name, exceptItemId: exceptItemId);

  Future<String?> lastUsedCategoryId() => _dao.lastUsedCategoryId(_shopId);

  Future<PriceSettings> priceSettings() => _dao.priceSettings(_shopId);

  Stream<PriceSettings> watchPriceSettings() =>
      _dao.watchPriceSettings(_shopId);

  /// Owner only (the server enforces it too). A new rate records when and
  /// by whom; an unchanged one keeps its "last edited".
  Future<Result<PriceSettings>> savePriceSettings(PriceSettings next) async {
    if (_scope.role != MemberRole.owner) {
      return const Err(AppException('Only the owner changes shop settings.'));
    }
    final now = _clock();
    final current = await _dao.priceSettings(_shopId);
    final saved = next.khrPerUsd == current.khrPerUsd
        ? next.copyWith(
            rateUpdatedAt: current.rateUpdatedAt,
            rateUpdatedBy: current.rateUpdatedBy,
          )
        : next.copyWith(rateUpdatedAt: now, rateUpdatedBy: _scope.userId);
    await _dao.savePriceSettings(
      _shopId,
      saved,
      now: now,
      userId: _scope.userId,
    );
    await _queue(
      SyncEntityType.shopSettings,
      _shopId,
      SyncOperation.update,
      now,
    );
    return Ok(saved);
  }

  Future<String?> memberName(String userId) => _dao.memberName(_shopId, userId);

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

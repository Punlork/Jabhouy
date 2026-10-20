import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/src/data/db/item_dao.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Push side and pull side for the redesign's Shop-scoped data: Items,
/// categories and the Shop's price settings. Each adapter re-reads the
/// row on every attempt (a job queued before a fix still sends the fixed
/// row) and builds the body the contract (jabhouy-api #2) names. Each
/// applier writes what `/changes` returns.
///
/// They talk to a [ShopSyncApi], so moving from the in-memory server to
/// HTTP changes the one object the app registers, and nothing here.

Map<String, Object?> _itemBody(Item item) => {
  'id': item.id,
  'name': item.name,
  'nicknames': item.nicknames,
  'categoryId': item.categoryId,
  'photoUrl': item.photoUrl,
  'note': item.note,
  'prices': [
    for (final p in item.prices)
      {
        'id': p.id,
        'unit': p.unit,
        'packQty': p.packQty,
        'barcode': p.barcode,
        'currency': p.currency.name.toUpperCase(),
        'price': p.price,
        'wholesale': p.wholesale,
        'cost': p.cost,
        'sortOrder': p.sortOrder,
      },
  ],
};

Map<String, Object?> _categoryBody(ItemCategory c) => {
  'id': c.id,
  'name': c.name,
  'sortOrder': c.sortOrder,
  'hidden': c.hidden,
  'units': [
    for (final u in c.units) {'unit': u.unit, 'hidden': u.hidden},
  ],
};

Map<String, Object?> _settingsBody(PriceSettings s) => {
  'useWholesalePrice': s.useWholesale,
  'useCostPrice': s.useCost,
  'defaultCurrency': s.currency.name.toUpperCase(),
  'khrPerUsd': s.khrPerUsd,
  'showConverted': s.showConverted,
};

Future<SyncPushOutcome> _send(
  String shopId,
  Future<Result<void>> Function() call,
) async => switch (await call()) {
  Ok() => const SyncPushSucceeded(),
  Err(:final error) => outcomeForShopWrite(error, shopId),
};

/// `PUT` or `DELETE /shops/:id/items/:itemId`.
class ItemSyncAdapter implements FeatureSyncAdapter {
  const ItemSyncAdapter(this._dao, this._api, this._shopId);

  final ItemDao _dao;
  final ShopSyncApi _api;
  final String Function() _shopId;

  @override
  SyncEntityType get entityType => SyncEntityType.item;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    final shopId = _shopId();
    final item = entry.operation == SyncOperation.delete
        ? null
        : await _dao.liveItem(entry.localId);
    // An update of a row deleted since is the delete.
    return _send(
      shopId,
      () => item == null
          ? _api.delete(shopId, entityType, entry.localId)
          : _api.put(shopId, entityType, item.id, _itemBody(item)),
    );
  }
}

/// `PUT` or `DELETE /shops/:id/categories/:catId`.
class ItemCategorySyncAdapter implements FeatureSyncAdapter {
  const ItemCategorySyncAdapter(this._dao, this._api, this._shopId);

  final ItemDao _dao;
  final ShopSyncApi _api;
  final String Function() _shopId;

  @override
  SyncEntityType get entityType => SyncEntityType.itemCategory;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    final shopId = _shopId();
    final category = entry.operation == SyncOperation.delete
        ? null
        : await _dao.liveCategory(entry.localId);
    return _send(
      shopId,
      () => category == null
          ? _api.delete(shopId, entityType, entry.localId)
          : _api.put(shopId, entityType, category.id, _categoryBody(category)),
    );
  }
}

/// `PUT /shops/:id/settings`; the job's `localId` is the Shop's id.
class ShopSettingsSyncAdapter implements FeatureSyncAdapter {
  const ShopSettingsSyncAdapter(this._dao, this._api);

  final ItemDao _dao;
  final ShopSyncApi _api;

  @override
  SyncEntityType get entityType => SyncEntityType.shopSettings;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    final shopId = entry.localId;
    final settings = await _dao.priceSettings(shopId);
    return _send(
      shopId,
      () => _api.put(shopId, entityType, shopId, _settingsBody(settings)),
    );
  }
}

class ItemChangeApplier implements ChangeApplier {
  const ItemChangeApplier(this._dao);

  final ItemDao _dao;

  @override
  SyncEntityType get entityType => SyncEntityType.item;

  @override
  Future<void> apply(
    String shopId,
    List<Map<String, Object?>> rows, {
    required Set<String> skipIds,
  }) => _dao.applyItems(shopId, rows, skipIds);
}

class ItemCategoryChangeApplier implements ChangeApplier {
  const ItemCategoryChangeApplier(this._dao);

  final ItemDao _dao;

  @override
  SyncEntityType get entityType => SyncEntityType.itemCategory;

  @override
  Future<void> apply(
    String shopId,
    List<Map<String, Object?>> rows, {
    required Set<String> skipIds,
  }) => _dao.applyCategories(shopId, rows, skipIds);
}

class ShopSettingsChangeApplier implements ChangeApplier {
  const ShopSettingsChangeApplier(this._dao);

  final ItemDao _dao;

  @override
  SyncEntityType get entityType => SyncEntityType.shopSettings;

  @override
  Future<void> apply(
    String shopId,
    List<Map<String, Object?>> rows, {
    required Set<String> skipIds,
  }) => _dao.applySettings(shopId, rows.last, skipIds);
}

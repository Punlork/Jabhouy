import 'package:jabhouy/shop/models/category_model.dart';
import 'package:jabhouy/shop/models/shop_item_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// The seam the shop bloc talks to. Shop earns no `logic/` layer under the
/// three conditions in `docs/ARCHITECTURE_RESTRUCTURE.md`, so the
/// repository is the boundary, and it is an interface so tests can stand a
/// double behind it.
///
/// Note what is absent. The old `ShopService` took a `localOnly` flag on
/// every write and called itself with `localOnly: false` from its own
/// drain loop; deciding "am I the user's write or the sync engine's push?"
/// is the repository's business, not the caller's. And nothing here
/// returns a message: an [Ok] says the write landed locally, the returned
/// row says whether it is still pending, and what to put on screen is the
/// `ui` layer's call.
///
/// This file imports no Flutter, which is what lets `logic/` import a
/// repository without inheriting one.
abstract class ShopRepository {
  Stream<List<ShopItemModel>> watchItems({
    String searchQuery = '',
    CategoryItemModel? categoryFilter,
  });

  Future<bool> hasCachedItems({
    String searchQuery = '',
    CategoryItemModel? categoryFilter,
  });

  /// Pulls a page from the server and caches it. The items themselves
  /// reach the bloc through [watchItems]; this returns the page so the
  /// bloc can page.
  Future<Result<PaginatedResponse<ShopItemModel>>> refreshItems({
    int page,
    int limit,
    String searchQuery,
    String categoryFilter,
  });

  Future<Result<ShopItemModel>> createItem(ShopItemModel body);

  Future<Result<ShopItemModel>> updateItem(ShopItemModel body);

  Future<Result<void>> deleteItem(ShopItemModel body);

  /// Pushes every queued write. Delegates to `SyncEngine.drain()`.
  Future<void> syncPendingChanges();
}

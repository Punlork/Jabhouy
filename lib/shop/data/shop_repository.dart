import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';

/// The seam the shop bloc talks to. Shop earns no `logic/` layer under the
/// three conditions in `docs/ARCHITECTURE_RESTRUCTURE.md`, so the
/// repository is the boundary, and it is an interface so tests can stand a
/// double behind it.
///
/// Note what is absent: the old `ShopService` took a `localOnly` flag on
/// every write and called itself with `localOnly: false` from its own drain
/// loop. Deciding "am I the user's write or the sync engine's push?" from a
/// flag on a public method is the repository's business, not the caller's.
/// Every method here is the user's write; pushing is [syncPendingChanges].
abstract class ShopRepository {
  Stream<List<ShopItemModel>> watchItems({
    String searchQuery = '',
    CategoryItemModel? categoryFilter,
  });

  Future<bool> hasCachedItems({
    String searchQuery = '',
    CategoryItemModel? categoryFilter,
  });

  /// Pulls a page from the server and caches it. Returns the server's
  /// pagination so the bloc can page; the items themselves reach the bloc
  /// through [watchItems].
  Future<ApiResponse<PaginatedResponse<ShopItemModel>>> refreshItems({
    int page,
    int limit,
    String searchQuery,
    String categoryFilter,
  });

  Future<ApiResponse<ShopItemModel?>> createItem(ShopItemModel body);

  Future<ApiResponse<ShopItemModel?>> updateItem(ShopItemModel body);

  Future<ApiResponse<dynamic>> deleteItem(ShopItemModel body);

  /// Pushes every pending row. Phase 3 replaces this body with the
  /// `jabhouy_sync` outbox drain; the signature is what survives.
  Future<void> syncPendingChanges();
}

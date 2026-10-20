import 'package:jabhouy_core/jabhouy_core.dart';

/// One page of `GET /shops/:id/changes`: rows with a `seq` above the
/// requested one, oldest first, grouped by entity type. A deleted row
/// carries `deletedAt` (a tombstone). Rows are the contract's JSON; this
/// package does not know what an Item is, the feature's [ChangeApplier]
/// does.
class ChangesPage {
  const ChangesPage({
    required this.cursor,
    this.hasMore = false,
    this.rows = const {},
  });

  /// The highest `seq` in this page; the next request's `since`.
  final int cursor;
  final bool hasMore;
  final Map<SyncEntityType, List<Map<String, Object?>>> rows;
}

/// The one place the app reads the server's changes.
// A port, like SyncTransport: the engine needs one thing, tests fake it.
// ignore: one_member_abstracts
abstract interface class ChangesSource {
  Future<Result<ChangesPage>> changes(
    String shopId, {
    required int since,
    int limit = 200,
  });
}

/// Everything shop-scoped the server offers: pull and push.
///
/// This is the seam to swap: the app registers `InMemoryShopSyncApi` until
/// the real `/shops/:id/…` routes (jabhouy-api #3–#8) are live, then one
/// HTTP implementation replaces it and nothing else changes.
abstract interface class ShopSyncApi implements ChangesSource {
  /// `PUT /shops/:id/<type>/:id`: creates or replaces; twice is harmless.
  Future<Result<void>> put(
    String shopId,
    SyncEntityType type,
    String id,
    Map<String, Object?> body,
  );

  /// `DELETE /shops/:id/<type>/:id`: the server keeps a tombstone.
  Future<Result<void>> delete(String shopId, SyncEntityType type, String id);
}

/// An error the server names with a `code` (`forbidden_role`,
/// `not_member`, `customer_has_credits`), as `{ code, message }`.
class ShopApiException extends AppException {
  const ShopApiException(this.code, int status, [String? message])
    : super(message ?? code, statusCode: status);

  final String code;

  static const forbiddenRole = ShopApiException('forbidden_role', 403);
  static const notMember = ShopApiException('not_member', 403);
}

/// Applies a page's rows of one entity type to the phone's tables.
///
/// Called inside the engine's transaction, with the ids of rows that still
/// have a queued local job in `skipIds`: the phone's copy of those is
/// newer, so the applier leaves them alone. A row with `deletedAt` is a
/// tombstone: hide it the way a local delete does.
abstract interface class ChangeApplier {
  SyncEntityType get entityType;

  Future<void> apply(
    String shopId,
    List<Map<String, Object?>> rows, {
    required Set<String> skipIds,
  });
}

import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/src/shop_api.dart';

/// A [ShopSyncApi] that keeps the Shop's rows in memory and behaves like the
/// contract: a per-Shop `seq` on every write, tombstones on delete,
/// `changes` paged oldest first. The app runs on it until the real API is
/// live, and tests drive it as a second device.
///
/// shortcut: rows live in memory, so a restart empties it; the phone's own
/// database keeps working. Gone when the HTTP implementation replaces it.
class InMemoryShopSyncApi implements ShopSyncApi {
  InMemoryShopSyncApi({this.userId = 'u1', DateTime Function() clock = DateTime.now})
    : _clock = clock;

  /// Stamped as `updatedBy` on every write.
  final String userId;
  final DateTime Function() _clock;

  final _shops = <String, _Shop>{};

  /// Errors to answer with, one per call, oldest first. Lets a test play
  /// the server saying `forbidden_role`, `not_member` or 409.
  final failures = <AppException>[];

  /// Every `put`/`delete` that reached the "server", for assertions.
  final writes = <String>[];

  Result<T>? _failure<T>() =>
      failures.isEmpty ? null : Err(failures.removeAt(0));

  @override
  Future<Result<void>> put(
    String shopId,
    SyncEntityType type,
    String id,
    Map<String, Object?> body,
  ) async {
    if (_failure<void>() case final failure?) return failure;
    writes.add('put ${type.name} $id');
    final shop = _shops.putIfAbsent(shopId, _Shop.new);
    final key = (type, id);
    final row = {...body};
    final before = shop.rows[key]?.json;
    // Units are only ever added or hidden by a PUT, never removed.
    if (type == SyncEntityType.itemCategory && before != null) {
      row['units'] = _mergeUnits(before['units'], row['units']);
    }
    shop.rows[key] = _Row(
      {
        ...row,
        'id': id,
        'updatedAt': _clock().toUtc().toIso8601String(),
        'updatedBy': userId,
        'deletedAt': null,
      },
      ++shop.seq,
    );
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(
    String shopId,
    SyncEntityType type,
    String id,
  ) async {
    if (_failure<void>() case final failure?) return failure;
    writes.add('delete ${type.name} $id');
    final shop = _shops.putIfAbsent(shopId, _Shop.new);
    final key = (type, id);
    final now = _clock().toUtc().toIso8601String();
    shop.rows[key] = _Row(
      {
        ...?shop.rows[key]?.json,
        'id': id,
        'updatedAt': now,
        'updatedBy': userId,
        'deletedAt': now,
      },
      ++shop.seq,
    );
    return const Ok(null);
  }

  @override
  Future<Result<ChangesPage>> changes(
    String shopId, {
    required int since,
    int limit = 200,
  }) async {
    if (_failure<ChangesPage>() case final failure?) return failure;
    final newer = [
      for (final entry in (_shops[shopId]?.rows ?? const {}).entries)
        if (entry.value.seq > since) (entry.key.$1, entry.value),
    ]..sort((a, b) => a.$2.seq.compareTo(b.$2.seq));
    final page = newer.take(limit).toList();
    final rows = <SyncEntityType, List<Map<String, Object?>>>{};
    for (final (type, row) in page) {
      rows.putIfAbsent(type, () => []).add({...row.json, 'seq': row.seq});
    }
    return Ok(
      ChangesPage(
        cursor: page.isEmpty ? since : page.last.$2.seq,
        hasMore: newer.length > page.length,
        rows: rows,
      ),
    );
  }

  static List<Object?> _mergeUnits(Object? before, Object? sent) {
    final merged = <String, Object?>{
      for (final unit in (before as List?) ?? const [])
        (unit! as Map)['unit']! as String: unit,
      for (final unit in (sent as List?) ?? const [])
        (unit! as Map)['unit']! as String: unit,
    };
    return merged.values.toList();
  }
}

class _Shop {
  int seq = 0;
  final rows = <(SyncEntityType, String), _Row>{};
}

class _Row {
  const _Row(this.json, this.seq);

  final Map<String, Object?> json;
  final int seq;
}

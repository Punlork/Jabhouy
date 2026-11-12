import 'package:flutter/foundation.dart';
import 'package:jabhouy/membership/membership.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// A [ShopSyncApi] for the API as it is today: routes scoped by user
/// (`/items/:id`), not by Shop. The Shop id is ignored.
///
/// The API stores money as decimals (USD `12.5`, not 1250 cents) and takes
/// `dueDate` as an ISO datetime; the adapters' bodies follow the final
/// contract (cents, `YYYY-MM-DD`), so [toApiBody] converts here.
///
/// `GET /changes` is per user here, so the Shop id is ignored on pull too.
///
/// With [shopScoped] (FEATURE_SERVER_SHOPS) every route moves under
/// `/shops/:id/…` and shop settings sync too; without it settings are
/// skipped, since the user-scoped API has no route for them.
class UserScopedShopSyncApi implements ShopSyncApi {
  const UserScopedShopSyncApi(this._api, {this.shopScoped = false});

  final ApiService _api;
  final bool shopScoped;

  static const _paths = {
    SyncEntityType.item: '/items',
    SyncEntityType.itemCategory: '/categories',
    SyncEntityType.creditCustomer: '/customers',
    SyncEntityType.credit: '/credits',
  };

  /// Where a [type] row with [id] lives, or null when the API has no route.
  @visibleForTesting
  static String? pathFor(
    String shopId,
    SyncEntityType type,
    String id, {
    required bool shopScoped,
  }) {
    if (!shopScoped) {
      final path = _paths[type];
      return path == null ? null : '$path/$id';
    }
    // Settings are one row per Shop, so there is no id in the path.
    if (type == SyncEntityType.shopSettings) return '/shops/$shopId/settings';
    final path = _paths[type];
    return path == null ? null : '/shops/$shopId$path/$id';
  }

  /// [body] as the user-scoped API wants it; the `id` is in the path.
  @visibleForTesting
  static Map<String, Object?> toApiBody(
    SyncEntityType type,
    Map<String, Object?> body,
  ) {
    final out = {...body}..remove('id');
    if (type == SyncEntityType.item) {
      out['prices'] = [
        for (final p in out['prices']! as List<Object?>)
          _money(p! as Map<String, Object?>, const [
            'price',
            'wholesale',
            'cost',
          ]),
      ];
    } else if (type == SyncEntityType.credit) {
      out
        ..addAll(_money(out, const ['amount']))
        ..['items'] = [
          for (final l in out['items']! as List<Object?>)
            _line(l! as Map<String, Object?>, out['currency']),
        ];
      final due = out['dueDate'] as String?;
      if (due != null && !due.contains('T')) {
        out['dueDate'] = DateTime.parse(due).toUtc().toIso8601String();
      }
    }
    return out;
  }

  /// A change row as the appliers read it: cents for USD, the due date as
  /// the local day it was set for.
  @visibleForTesting
  static Map<String, Object?> fromApiRow(
    SyncEntityType type,
    Map<String, Object?> row,
  ) {
    final out = {...row};
    if (type == SyncEntityType.item) {
      out['prices'] = [
        for (final p in out['prices']! as List<Object?>)
          _money(p! as Map<String, Object?>, const [
            'price',
            'wholesale',
            'cost',
          ], toApi: false),
      ];
    } else if (type == SyncEntityType.credit) {
      out
        ..addAll(_money(out, const ['amount'], toApi: false))
        ..['items'] = [
          for (final l in out['items']! as List<Object?>)
            _line(l! as Map<String, Object?>, out['currency'], toApi: false),
        ];
      final due = out['dueDate'] as String?;
      if (due != null) {
        out['dueDate'] = DateTime.parse(due).toLocal().toIsoDate();
      }
    }
    return out;
  }

  /// A credit line: `unitPrice` is in the line's currency, `total` in the
  /// Credit's ([creditCurrency]), so each scales by its own.
  static Map<String, Object?> _line(
    Map<String, Object?> line,
    Object? creditCurrency, {
    bool toApi = true,
  }) => _money(
    _money(line, const ['unitPrice'], toApi: toApi),
    const ['total'],
    toApi: toApi,
    currency: creditCurrency,
  );

  static Map<String, Object?> _money(
    Map<String, Object?> row,
    List<String> keys, {
    bool toApi = true,
    Object? currency,
  }) {
    final out = {...row};
    final usd = (currency ?? row['currency']) == 'USD';
    for (final k in keys) {
      final v = out[k] as num?;
      if (v == null) continue;
      out[k] = toApi
          ? (usd ? v / 100 : v)
          : (usd ? (v * 100).round() : v.round());
    }
    return out;
  }

  @override
  Future<Result<void>> put(
    String shopId,
    SyncEntityType type,
    String id,
    Map<String, Object?> body,
  ) async {
    final path = pathFor(shopId, type, id, shopScoped: shopScoped);
    if (path == null) return const Ok(null);
    final response = await _api.put<dynamic>(
      path,
      body: toApiBody(type, body),
      showSnackBar: false,
    );
    return response.toShopVoidResult();
  }

  @override
  Future<Result<void>> delete(
    String shopId,
    SyncEntityType type,
    String id,
  ) async {
    final path = pathFor(shopId, type, id, shopScoped: shopScoped);
    if (path == null) return const Ok(null);
    final response = await _api.delete<dynamic>(path, showSnackBar: false);
    // Already gone is what a delete wants.
    if (response.statusCode == 404) return const Ok(null);
    return response.toShopVoidResult();
  }

  static const _changeKeys = {
    'items': SyncEntityType.item,
    'categories': SyncEntityType.itemCategory,
    'customers': SyncEntityType.creditCustomer,
    'credits': SyncEntityType.credit,
  };

  @override
  Future<Result<ChangesPage>> changes(
    String shopId, {
    required int since,
    int limit = 200,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      shopScoped ? '/shops/$shopId/changes' : '/changes',
      queryParameters: {'since': '$since', 'limit': '$limit'},
      showSnackBar: false,
      parser: (v) => v as Map<String, dynamic>,
    );
    final data = response.data;
    if (!response.success || data == null) {
      return Err(
        response.shopError ??
            AppException(
              response.message ?? 'Request failed.',
              statusCode: response.statusCode,
            ),
      );
    }
    return Ok(
      ChangesPage(
        cursor: int.tryParse('${data['cursor']}') ?? since,
        hasMore: data['hasMore'] == true,
        rows: {
          for (final entry in _changeKeys.entries)
            if ((data[entry.key] as List?)?.isNotEmpty ?? false)
              entry.value: [
                for (final row in data[entry.key] as List<dynamic>)
                  fromApiRow(entry.value, row as Map<String, Object?>),
              ],
          // Sent only when it changed; null otherwise.
          if (data['settings'] case final Map<String, Object?> settings)
            SyncEntityType.shopSettings: [settings],
        },
      ),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/service/user_scoped_shop_sync_api.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

void main() {
  test('a USD credit goes as dollars, a line total by the credit currency', () {
    final body = UserScopedShopSyncApi.toApiBody(SyncEntityType.credit, {
      'id': 'c1',
      'currency': 'USD',
      'amount': 1250,
      'dueDate': '2026-11-01',
      'items': [
        {'currency': 'USD', 'unitPrice': 625, 'total': 1250},
        // Riel price, total already converted to the credit's cents.
        {'currency': 'KHR', 'unitPrice': 3000, 'total': 75},
      ],
    });
    expect(body.containsKey('id'), isFalse);
    expect(body['amount'], 12.5);
    expect(
      body['dueDate'],
      DateTime.parse('2026-11-01').toUtc().toIso8601String(),
    );
    final lines = body['items']! as List;
    expect((lines[0] as Map)['unitPrice'], 6.25);
    expect((lines[1] as Map)['unitPrice'], 3000);
    expect((lines[1] as Map)['total'], 0.75);
  });

  test('a USD line on a KHR credit: dollar price, riel total untouched', () {
    final body = UserScopedShopSyncApi.toApiBody(SyncEntityType.credit, {
      'id': 'c2',
      'currency': 'KHR',
      'amount': 400000,
      'dueDate': null,
      'items': [
        {'currency': 'USD', 'unitPrice': 10000, 'total': 400000},
      ],
    });
    final line = (body['items']! as List).single as Map;
    expect(line['unitPrice'], 100);
    expect(line['total'], 400000);
  });

  test('an item USD price goes as dollars and a missing one stays null', () {
    final body = UserScopedShopSyncApi.toApiBody(SyncEntityType.item, {
      'id': 'i1',
      'prices': [
        {'currency': 'USD', 'price': 750, 'wholesale': null, 'cost': 500},
      ],
    });
    final price = (body['prices']! as List).single as Map;
    expect(price['price'], 7.5);
    expect(price['wholesale'], isNull);
    expect(price['cost'], 5);
  });

  test('a pulled USD credit comes back as cents and a local due day', () {
    final due = DateTime(2026, 11).toUtc().toIso8601String();
    final row = UserScopedShopSyncApi.fromApiRow(SyncEntityType.credit, {
      'id': 'c1',
      'currency': 'USD',
      'amount': 12.5,
      'dueDate': due,
      'items': [
        {'currency': 'USD', 'unitPrice': 6.25, 'total': 12.5},
        {'currency': 'KHR', 'unitPrice': 3000, 'total': 0.75},
      ],
    });
    expect(row['amount'], 1250);
    expect(row['dueDate'], '2026-11-01');
    final lines = row['items']! as List;
    expect((lines[0] as Map)['unitPrice'], 625);
    expect((lines[1] as Map)['unitPrice'], 3000);
    expect((lines[1] as Map)['total'], 75);
  });

  test('shop-scoped paths nest under the Shop; user-scoped ones do not', () {
    String? path(SyncEntityType t, {required bool scoped}) =>
        UserScopedShopSyncApi.pathFor('s1', t, 'x1', shopScoped: scoped);
    expect(path(SyncEntityType.item, scoped: true), '/shops/s1/items/x1');
    expect(path(SyncEntityType.credit, scoped: true), '/shops/s1/credits/x1');
    expect(
      path(SyncEntityType.shopSettings, scoped: true),
      '/shops/s1/settings',
    );
    expect(path(SyncEntityType.item, scoped: false), '/items/x1');
    expect(path(SyncEntityType.shopSettings, scoped: false), isNull);
  });
}

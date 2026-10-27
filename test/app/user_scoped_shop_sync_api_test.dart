import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/service/user_scoped_shop_sync_api.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

void main() {
  test(
    'a USD credit goes as dollars, KHR untouched, dueDate as a datetime',
    () {
      final body = UserScopedShopSyncApi.toApiBody(SyncEntityType.credit, {
        'id': 'c1',
        'currency': 'USD',
        'amount': 1250,
        'dueDate': '2026-11-01',
        'items': [
          {'currency': 'USD', 'unitPrice': 625, 'total': 1250},
          {'currency': 'KHR', 'unitPrice': 3000, 'total': 3000},
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
      expect((lines[1] as Map)['total'], 3000);
    },
  );

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
        {'currency': 'KHR', 'unitPrice': 3000, 'total': 3000},
      ],
    });
    expect(row['amount'], 1250);
    expect(row['dueDate'], '2026-11-01');
    final lines = row['items']! as List;
    expect((lines[0] as Map)['unitPrice'], 625);
    expect((lines[1] as Map)['total'], 3000);
  });
}

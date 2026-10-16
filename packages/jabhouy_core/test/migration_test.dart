// Runs under `dart test`. There are no committed schema snapshots yet, so
// this builds a schema-7 file by hand: today's tables minus the one 8 adds.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:test/test.dart';

void main() {
  test('7 -> 8 adds sync_cursors and keeps the outbox and its rows',
      () async {
    final dir = await Directory.systemTemp.createTemp('jabhouy_migration');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    final old = AppDatabase(NativeDatabase(file));
    await old.into(old.outboxEntries).insert(
          OutboxEntriesCompanion.insert(
            entityType: SyncEntityType.loaner,
            localId: '37',
            operation: SyncOperation.update,
            idempotencyKey: 'loaner:37:update',
          ),
        );
    await old.customStatement('DROP TABLE sync_cursors');
    await old.customStatement('PRAGMA user_version = 7');
    await old.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    expect(await upgraded.select(upgraded.syncCursors).get(), isEmpty);
    final jobs = await upgraded.select(upgraded.outboxEntries).get();
    expect(jobs.single.localId, '37', reason: 'a queued edit survives');
    await upgraded.into(upgraded.syncCursors).insert(
          SyncCursorsCompanion.insert(
            entityType: SyncEntityType.loaner,
            lastPulledAt: DateTime(2026, 9, 28),
          ),
        );
  });

  test('8 -> 9 adds the redesign tables and keeps old rows', () async {
    final dir = await Directory.systemTemp.createTemp('jabhouy_migration');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    final old = AppDatabase(NativeDatabase(file));
    await old.into(old.customers).insert(
          CustomersCompanion.insert(id: const Value(1), name: 'សុខា'),
        );
    await old.into(old.shopItems).insert(
          ShopItemsCompanion.insert(id: const Value(2), name: 'Coca-Cola'),
        );
    for (final name in [
      'shop_settings',
      'member',
      'category',
      'category_unit',
      'item',
      'item_price',
      'customer',
      'credit',
      'credit_item',
    ]) {
      await old.customStatement('DROP TABLE $name');
    }
    await old.customStatement('PRAGMA user_version = 8');
    await old.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    final customers = await upgraded.select(upgraded.customers).get();
    expect(customers.single.name, 'សុខា', reason: 'old rows survive');
    final items = await upgraded.select(upgraded.shopItems).get();
    expect(items.single.name, 'Coca-Cola');
    expect(await upgraded.select(upgraded.itemTable).get(), isEmpty);
    expect(await upgraded.select(upgraded.creditItemTable).get(), isEmpty);
    await upgraded.into(upgraded.itemTable).insert(
          ItemTableCompanion.insert(id: newId(), shopId: 's1', name: 'ទឹក'),
        );
  });
}

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
      'recent_item',
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

  test('9 -> 10 adds nicknames, barcode and recent_item; items survive',
      () async {
    final dir = await Directory.systemTemp.createTemp('jabhouy_migration');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    final old = AppDatabase(NativeDatabase(file));
    await old.into(old.itemTable).insert(
          ItemTableCompanion.insert(id: 'coke', shopId: 's1', name: 'Coca-Cola'),
        );
    await old.customStatement('DROP TABLE recent_item');
    await old.customStatement('ALTER TABLE item DROP COLUMN nicknames');
    await old.customStatement('ALTER TABLE item_price DROP COLUMN barcode');
    await old.customStatement('PRAGMA user_version = 9');
    await old.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    final items = await upgraded.select(upgraded.itemTable).get();
    expect(items.single.name, 'Coca-Cola', reason: 'old rows survive');
    expect(items.single.nicknames, '[]');
    expect(await upgraded.select(upgraded.recentItemTable).get(), isEmpty);
    await upgraded.into(upgraded.itemPriceTable).insert(
          ItemPriceTableCompanion.insert(
            id: newId(),
            itemId: 'coke',
            unit: 'ដប',
            currency: 'KHR',
            barcode: const Value('8851234567890'),
          ),
        );
  });

  test('10 -> 11 adds shop_sync_cursors; rows survive', () async {
    final dir = await Directory.systemTemp.createTemp('jabhouy_migration');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    final old = AppDatabase(NativeDatabase(file));
    await old.into(old.itemTable).insert(
          ItemTableCompanion.insert(id: 'coke', shopId: 's1', name: 'Coca-Cola'),
        );
    await old.customStatement('DROP TABLE shop_sync_cursors');
    await old.customStatement('PRAGMA user_version = 10');
    await old.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    expect((await upgraded.select(upgraded.itemTable).get()).single.id, 'coke');
    expect(await upgraded.select(upgraded.shopSyncCursors).get(), isEmpty);
  });

  test('wipeShop removes one Shop and leaves the other', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    for (final shop in ['s1', 's2']) {
      await db.into(db.itemTable).insert(
            ItemTableCompanion.insert(id: 'i-$shop', shopId: shop, name: shop),
          );
      await db.into(db.itemPriceTable).insert(
            ItemPriceTableCompanion.insert(
              id: 'p-$shop',
              itemId: 'i-$shop',
              unit: 'ដប',
              currency: 'KHR',
            ),
          );
      await db.into(db.shopSyncCursors).insert(
            ShopSyncCursorsCompanion.insert(shopId: shop),
          );
    }

    await db.wipeShop('s1');

    expect((await db.select(db.itemTable).get()).map((i) => i.id), ['i-s2']);
    expect((await db.select(db.itemPriceTable).get()).map((p) => p.id), ['p-s2']);
    expect((await db.select(db.shopSyncCursors).get()).map((c) => c.shopId), ['s2']);
  });
}

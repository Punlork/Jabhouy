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
}

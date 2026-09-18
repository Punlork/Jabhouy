import 'package:drift/native.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  OutboxEntriesCompanion job(
    String localId, {
    SyncEntityType type = SyncEntityType.shopItem,
    SyncOperation operation = SyncOperation.create,
    String? dependsOn,
  }) =>
      OutboxEntriesCompanion.insert(
        entityType: type,
        entityLocalId: localId,
        operation: operation,
        fingerprint: '$type:$localId:$operation',
        dependsOnLocalId: Value(dependsOn),
      );

  test('a job round-trips with its enums and backoff defaults', () async {
    await db.into(db.outboxEntries).insert(job('item-1'));

    final entry = await db.select(db.outboxEntries).getSingle();
    expect(entry.entityType, SyncEntityType.shopItem);
    expect(entry.operation, SyncOperation.create);
    expect(entry.entityLocalId, 'item-1');

    // A fresh job is due immediately and has survived nothing.
    expect(entry.attemptCount, 0);
    expect(entry.lastError, isNull);
    expect(entry.nextAttemptAt, isNotNull);
  });

  test('a second write to the same row does not queue a second push',
      () async {
    await db.into(db.outboxEntries).insert(job('item-1'));

    await expectLater(
      db.into(db.outboxEntries).insert(job('item-1')),
      throwsA(isA<SqliteException>()),
    );

    // Same local id, different table, is a different job.
    await db
        .into(db.outboxEntries)
        .insert(job('item-1', type: SyncEntityType.category));
    expect(await db.select(db.outboxEntries).get(), hasLength(2));
  });

  test('a job can name the job it waits for', () async {
    await db
        .into(db.outboxEntries)
        .insert(job('cat-1', type: SyncEntityType.category));
    await db.into(db.outboxEntries).insert(job('item-1', dependsOn: 'cat-1'));

    final item = await (db.select(db.outboxEntries)
          ..where((t) => t.entityLocalId.equals('item-1')))
        .getSingle();
    expect(item.dependsOnLocalId, 'cat-1');
  });

  test('the drain index exists so the due-jobs query stays cheap', () async {
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type = 'index' AND name = 'outbox_drain_idx'",
        )
        .get();

    expect(rows, hasLength(1));
  });

  test('the schema is at the version that introduced the outbox', () async {
    expect(db.schemaVersion, 6);
    expect(await db.select(db.outboxEntries).get(), isEmpty);
  });
}

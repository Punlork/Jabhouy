// Runs under `dart test`. A Flutter import anywhere in this package stops
// the suite loading, which is what keeps the engine platform-free.
import 'package:drift/native.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:test/test.dart';

/// A transport whose answers the test dictates, one per push.
class _ScriptedTransport implements SyncTransport {
  _ScriptedTransport(this.outcomes);

  final List<SyncPushOutcome> outcomes;
  final pushed = <OutboxEntry>[];

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    pushed.add(entry);
    return outcomes.isEmpty
        ? const SyncPushSucceeded()
        : outcomes.removeAt(0);
  }
}

void main() {
  late AppDatabase db;
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    // Local, not UTC: drift stores unix seconds and reads back local.
    now = DateTime(2026, 9, 18, 12);
  });

  tearDown(() async {
    await db.close();
  });

  SyncEngine engineWith(
    _ScriptedTransport transport, {
    BackoffPolicy backoff = const BackoffPolicy(),
  }) =>
      SyncEngine(
        database: db,
        transport: transport,
        backoff: backoff,
        clock: () => now,
      );

  Future<void> enqueueItem(
    SyncEngine engine,
    String localId, {
    SyncEntityType type = SyncEntityType.shopItem,
    String? dependsOn,
  }) =>
      engine.enqueue(
        entityType: type,
        entityLocalId: localId,
        operation: SyncOperation.create,
        fingerprint: 'fp-$localId',
        dependsOnLocalId: dependsOn,
      );

  test('a queued write leaves the outbox once the server accepts it',
      () async {
    final transport = _ScriptedTransport([const SyncPushSucceeded()]);
    final engine = engineWith(transport);

    await enqueueItem(engine, 'item-1');
    expect(await db.select(db.outboxEntries).get(), hasLength(1));

    expect(await engine.drain(), 1);
    expect(await db.select(db.outboxEntries).get(), isEmpty);
  });

  test('a transient failure retries with backoff and succeeds on attempt 3',
      () async {
    final transport = _ScriptedTransport([
      const SyncPushFailedTransiently('500'),
      const SyncPushFailedTransiently('500'),
      const SyncPushSucceeded(),
    ]);
    const backoff = BackoffPolicy(base: Duration(seconds: 10));
    final engine = engineWith(transport, backoff: backoff);

    await enqueueItem(engine, 'item-1');

    expect(await engine.drain(), 0);
    var entry = await db.select(db.outboxEntries).getSingle();
    expect(entry.attemptCount, 1);
    expect(entry.lastError, '500');
    expect(entry.nextAttemptAt, now.add(const Duration(seconds: 20)));

    // Still in the future: the drain loop must not pick it up yet.
    expect(await engine.drain(), 0);
    expect(transport.pushed, hasLength(1));

    now = now.add(const Duration(minutes: 1));
    expect(await engine.drain(), 0);
    entry = await db.select(db.outboxEntries).getSingle();
    expect(entry.attemptCount, 2);

    now = now.add(const Duration(minutes: 10));
    expect(await engine.drain(), 1);
    expect(await db.select(db.outboxEntries).get(), isEmpty);
    expect(transport.pushed, hasLength(3));
  });

  test('an item waits for the offline category it references', () async {
    final transport = _ScriptedTransport([]);
    final engine = engineWith(transport);

    await enqueueItem(engine, 'cat-1', type: SyncEntityType.category);
    await enqueueItem(engine, 'item-1', dependsOn: 'cat-1');

    // Only the category is eligible while its job is still queued.
    final due = await engine.dueEntries();
    expect(due.map((e) => e.entityLocalId), ['cat-1']);

    await engine.drain();
    expect(transport.pushed.map((e) => e.entityLocalId), ['cat-1', 'item-1']);
  });

  test('a rejected push keeps the job and its reason instead of dropping it',
      () async {
    final transport = _ScriptedTransport([const SyncPushRejected('400 bad')]);
    final engine = engineWith(transport);

    await enqueueItem(engine, 'item-1');
    expect(await engine.drain(), 0);

    final entry = await db.select(db.outboxEntries).getSingle();
    expect(entry.lastError, '400 bad');
    // The old code marked this synced and forgot it.
    expect(await db.select(db.outboxEntries).get(), hasLength(1));
  });

  test('a delete that fails remotely stays queued', () async {
    final transport =
        _ScriptedTransport([const SyncPushFailedTransiently('timeout')]);
    final engine = engineWith(transport);

    await engine.enqueue(
      entityType: SyncEntityType.shopItem,
      entityLocalId: 'item-1',
      operation: SyncOperation.delete,
      fingerprint: 'fp-delete-1',
    );

    expect(await engine.drain(), 0);
    final entry = await db.select(db.outboxEntries).getSingle();
    expect(entry.operation, SyncOperation.delete);
    expect(entry.lastError, 'timeout');
  });

  test('a second edit before the first is sent is still one push', () async {
    final transport = _ScriptedTransport([]);
    final engine = engineWith(transport);

    await enqueueItem(engine, 'item-1');
    await engine.enqueue(
      entityType: SyncEntityType.shopItem,
      entityLocalId: 'item-1',
      operation: SyncOperation.update,
      fingerprint: 'fp-item-1-v2',
    );

    expect(await db.select(db.outboxEntries).get(), hasLength(1));
    await engine.drain();
    expect(transport.pushed, hasLength(1));
    expect(transport.pushed.single.operation, SyncOperation.update);
  });

  test('concurrent drains of one fingerprint share a single push', () async {
    final transport = _ScriptedTransport([]);
    final engine = engineWith(transport);
    await enqueueItem(engine, 'item-1');

    await Future.wait([engine.drain(), engine.drain()]);

    expect(transport.pushed, hasLength(1));
  });

  test('backoff doubles and then stops at its ceiling', () {
    const policy = BackoffPolicy(
      base: Duration(seconds: 10),
      max: Duration(minutes: 1),
    );

    expect(policy.delayFor(0), const Duration(seconds: 10));
    expect(policy.delayFor(1), const Duration(seconds: 20));
    expect(policy.delayFor(2), const Duration(seconds: 40));
    expect(policy.delayFor(3), const Duration(minutes: 1));
    expect(policy.delayFor(99), const Duration(minutes: 1));
  });
}

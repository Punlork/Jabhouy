// Pulls `/changes` per Shop and the 403/409 rules, against the in-memory
// server. Runs under `dart test`.
import 'package:drift/native.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:test/test.dart';

/// Records what each pull handed it.
class _Applier implements ChangeApplier {
  _Applier(this.entityType);

  @override
  final SyncEntityType entityType;
  final calls = <(String, List<Map<String, Object?>>, Set<String>)>[];

  Iterable<String> get ids =>
      [for (final c in calls) for (final r in c.$2) r['id']! as String];

  @override
  Future<void> apply(
    String shopId,
    List<Map<String, Object?>> rows, {
    required Set<String> skipIds,
  }) async => calls.add((shopId, rows, skipIds));
}

/// Pushes an outbox job as a PUT, the way a feature adapter does.
class _PutTransport implements SyncTransport {
  _PutTransport(this.api, this.shopId);

  final ShopSyncApi api;
  final String shopId;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async =>
      switch (await api.put(shopId, entry.entityType, entry.localId, {})) {
        Ok() => const SyncPushSucceeded(),
        Err(:final error) => outcomeForShopWrite(error, shopId),
      };
}

void main() {
  late AppDatabase db;
  late InMemoryShopSyncApi api;
  late _Applier items;
  late SyncEngine engine;

  SyncEngine build({int pageSize = 200, SyncTransport? transport}) =>
      SyncEngine(
        database: db,
        transport: transport ?? _PutTransport(api, 's1'),
        changesSource: api,
        changeAppliers: [items],
        changesPageSize: pageSize,
      );

  Future<int> cursor(String shopId) async =>
      (await (db.select(db.shopSyncCursors)
                ..where((t) => t.shopId.equals(shopId)))
              .getSingleOrNull())
          ?.seq ??
      0;

  Future<void> put(String shop, String id) =>
      api.put(shop, SyncEntityType.item, id, {'name': id});

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = InMemoryShopSyncApi();
    items = _Applier(SyncEntityType.item);
    engine = build();
  });

  tearDown(() => db.close());

  test('pages until hasMore ends, and keeps the cursor', () async {
    for (final id in ['a', 'b', 'c', 'd', 'e']) {
      await put('s1', id);
    }
    engine = build(pageSize: 2);

    await engine.pullShop('s1');

    expect(items.calls.map((c) => c.$2.length), [2, 2, 1]);
    expect(items.ids, ['a', 'b', 'c', 'd', 'e']);
    expect(await cursor('s1'), 5);

    await engine.pullShop('s1');
    expect(items.calls, hasLength(3), reason: 'nothing newer, nothing applied');
  });

  test('a delete arrives as a tombstone after the row it deletes', () async {
    await put('s1', 'a');
    await put('s1', 'b');
    await api.delete('s1', SyncEntityType.item, 'a');

    await engine.pullShop('s1');

    final rows = items.calls.single.$2;
    expect(rows.map((r) => r['id']), ['b', 'a']);
    expect(rows.last['deletedAt'], isNotNull);
    expect(rows.first['deletedAt'], isNull);
  });

  test('each Shop has its own cursor', () async {
    await put('s1', 'a');
    await put('s2', 'x');
    await put('s2', 'y');

    await engine.pullShop('s1');
    await engine.pullShop('s2');

    expect(await cursor('s1'), 1);
    expect(await cursor('s2'), 2);
    expect(items.calls.map((c) => c.$1), ['s1', 's2']);
    await put('s1', 'b');
    await engine.pullShop('s1');
    expect(items.calls.last.$2.single['id'], 'b', reason: 's2 not re-read');
  });

  test('rows with a queued local job are handed over as skipIds', () async {
    await put('s1', 'a');
    await engine.enqueue(
      entityType: SyncEntityType.item,
      localId: 'a',
      operation: SyncOperation.update,
      idempotencyKey: 'k1',
    );
    // The push below would clear the job, so hold it with a failure.
    api.failures.add(const AppException.network('offline'));

    await engine.pullShop('s1');

    expect(items.calls.single.$3, {'a'});
  });

  test('a failed fetch applies nothing and keeps the cursor', () async {
    await put('s1', 'a');
    api.failures.add(const AppException.network('offline'));

    await engine.pullShop('s1');
    expect(items.calls, isEmpty);
    expect(await cursor('s1'), 0);

    await engine.pullShop('s1');
    expect(items.ids, ['a']);
  });

  group('server rules on a queued write', () {
    Future<void> queue() => engine.enqueue(
      entityType: SyncEntityType.item,
      localId: 'a',
      operation: SyncOperation.update,
      idempotencyKey: 'k1',
    );

    test('403 forbidden_role: dropped, noticed, pulled again', () async {
      await put('s1', 'a');
      await engine.pullShop('s1');
      expect(await cursor('s1'), 1);
      final notices = <SyncNotice>[];
      engine.notices.listen(notices.add);
      await queue();
      api.failures.add(ShopApiException.forbiddenRole);

      await engine.drain();
      await engine.pullShop('s1'); // joins the pull the drop started

      expect(await db.select(db.outboxEntries).get(), isEmpty);
      await pumpEventQueue();
      expect(notices, [SyncNotice.noPermission]);
      expect(items.calls.length, 2, reason: 'the whole Shop is read again');
      expect(items.calls.last.$2.single['id'], 'a');
    });

    test('409: dropped and pulled, without the no-permission notice',
        () async {
      final notices = <SyncNotice>[];
      engine.notices.listen(notices.add);
      await queue();
      api.failures.add(const ShopApiException('customer_has_credits', 409));

      await engine.drain();
      await pumpEventQueue();

      expect(await db.select(db.outboxEntries).get(), isEmpty);
      expect(notices, isEmpty);
    });

    test('403 not_member: that Shop is wiped, others stay', () async {
      for (final shop in ['s1', 's2']) {
        await db.into(db.itemTable).insert(
              ItemTableCompanion.insert(id: 'i-$shop', shopId: shop, name: shop),
            );
      }
      final notices = <SyncNotice>[];
      engine.notices.listen(notices.add);
      await queue();
      api.failures.add(ShopApiException.notMember);

      await engine.drain();
      await pumpEventQueue();

      expect((await db.select(db.itemTable).get()).map((i) => i.id), ['i-s2']);
      expect(await db.select(db.outboxEntries).get(), isEmpty);
      expect(notices, [SyncNotice.shopRemoved]);
    });

    test('403 not_member on a pull wipes the Shop too', () async {
      await db.into(db.itemTable).insert(
            ItemTableCompanion.insert(id: 'i1', shopId: 's1', name: 'x'),
          );
      api.failures.add(ShopApiException.notMember);

      await engine.pullShop('s1');

      expect(await db.select(db.itemTable).get(), isEmpty);
    });
  });

  test('without a changes source, pullShop does nothing', () async {
    final bare = SyncEngine(database: db, transport: _PutTransport(api, 's1'));
    await put('s1', 'a');
    await bare.pullShop('s1');
    expect(await cursor('s1'), 0);
  });
}

// The income slice. Income was already the one sync path that did not
// lose writes, so these are mostly about what the engine adds to it:
// an attempt count, a delay, and a job that survives a device that is not
// allowed to upload.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/income/income.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class _MockIncomeApi extends Mock implements IncomeApi {}

class _MockDiagnostics extends Mock implements IncomeDiagnostics {}

BankNotificationModel _notification(String fingerprint) {
  return BankNotificationModel(
    fingerprint: fingerprint,
    packageName: 'com.paygo24.ibank',
    bankApp: BankApp.aba,
    message: 'Incoming USD 10',
    receivedAt: DateTime(2026, 9, 21),
    isIncome: true,
  );
}

void main() {
  late AppDatabase db;
  late IncomeDao dao;
  late _MockIncomeApi api;
  late _MockDiagnostics diagnostics;

  setUpAll(() {
    registerFallbackValue(_notification('fallback'));
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = IncomeDao(db);
    api = _MockIncomeApi();
    diagnostics = _MockDiagnostics();
    when(
      () => diagnostics.log(
        source: any(named: 'source'),
        message: any(named: 'message'),
        level: any(named: 'level'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<OutboxEntry>> jobs() => db.select(db.outboxEntries).get();
  Future<List<BankNotification>> rows() => db.select(db.bankNotifications).get();

  ({DefaultIncomeRepository repository, SyncEngine engine}) chain({
    required Future<bool> Function(BankNotificationModel) upload,
    bool canCapture = true,
  }) {
    final engine = SyncEngine(
      database: db,
      transport: AppSyncTransport([
        IncomeSyncAdapter(dao, upload, () async => canCapture),
      ]),
    );
    return (repository: DefaultIncomeRepository(dao, api, engine), engine: engine);
  }

  group('upload', () {
    test('an upload that does not confirm keeps the job and backs off',
        () async {
      final c = chain(upload: (_) async => false);
      await dao.upsert(_notification('n-1'));
      await c.repository.enqueueUpload(_notification('n-1'));

      await c.engine.drain();

      expect((await rows()).single.syncStatus, SyncStatus.failed);
      final job = (await jobs()).single;
      expect(job.attemptCount, 1, reason: 'the old path had no attempt count');
      expect(job.nextAttemptAt.isAfter(DateTime.now()), isTrue);
    });

    test('a confirmed upload clears the job and marks the row synced',
        () async {
      final c = chain(upload: (_) async => true);
      await dao.upsert(_notification('n-1'));
      await c.repository.enqueueUpload(_notification('n-1'));

      await c.engine.drain();

      expect((await rows()).single.syncStatus, SyncStatus.synced);
      expect(await jobs(), isEmpty);
    });

    test('a device that is not the main device never uploads', () async {
      var uploads = 0;
      final c = chain(
        upload: (_) async {
          uploads++;
          return true;
        },
        canCapture: false,
      );
      await dao.upsert(_notification('n-1'));
      await c.repository.enqueueUpload(_notification('n-1'));

      await c.engine.drain();

      expect(uploads, 0);
      expect(
        (await jobs()).single.lastError,
        contains('main device'),
        reason: 'the job waits for promotion rather than being dropped',
      );
      expect(
        (await rows()).single.syncStatus,
        SyncStatus.pending,
        reason: 'not failed: nothing was attempted',
      );
    });

    test('the same fingerprint queued twice is still one job', () async {
      final c = chain(upload: (_) async => true);
      await dao.upsert(_notification('n-1'));

      await c.repository.enqueueUpload(_notification('n-1'));
      await c.repository.enqueueUpload(_notification('n-1'));

      expect((await jobs()).length, 1);
    });
  });

  group('PullRemoteNotificationsUseCase', () {
    late DefaultIncomeRepository repository;
    late DateTime now;
    late PullRemoteNotificationsUseCase pull;

    setUp(() {
      repository = chain(upload: (_) async => true).repository;
      now = DateTime(2026, 9, 21, 10);
      pull = PullRemoteNotificationsUseCase(
        repository,
        diagnostics,
        clock: () => now,
      );
    });

    test('stores what the server returned, and repairs what it can',
        () async {
      // The fixture arrives with no amount, as rows stored before the
      // parser understood them did. The backfill pass reads it back out
      // of the message, so the count is one stored plus one repaired.
      when(() => api.fetchNotifications())
          .thenAnswer((_) async => Ok([_notification('n-1')]));

      expect(await pull(), 2);

      final saved = (await rows()).single;
      expect(saved.fingerprint, 'n-1');
      expect(saved.amount, 10, reason: 'read out of "Incoming USD 10"');
    });

    test('a second call inside the window does not hit the server',
        () async {
      when(() => api.fetchNotifications())
          .thenAnswer((_) async => Ok([_notification('n-1')]));

      await pull();
      now = now.add(const Duration(seconds: 5));
      expect(await pull(), 0);

      verify(() => api.fetchNotifications()).called(1);
    });

    test('force ignores the window', () async {
      when(() => api.fetchNotifications())
          .thenAnswer((_) async => Ok([_notification('n-1')]));

      await pull();
      now = now.add(const Duration(seconds: 5));
      await pull(force: true);

      verify(() => api.fetchNotifications()).called(2);
    });

    test('a failed pull stores nothing and says why', () async {
      when(() => api.fetchNotifications()).thenAnswer(
        (_) async => const Err(AppException('bad gateway', statusCode: 502)),
      );

      expect(await pull(), 0);
      expect(await rows(), isEmpty);
      verify(
        () => diagnostics.log(
          source: any(named: 'source'),
          message: any(named: 'message'),
          level: 'warning',
          metadata: any(named: 'metadata'),
        ),
      ).called(1);
    });
  });
}

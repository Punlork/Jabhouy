import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Local-first loaner writes, queued through the app's one outbox.
class DefaultLoanerRepository implements LoanerRepository {
  const DefaultLoanerRepository(
    this._dao,
    this._api,
    this._engine,
    this._connectivity,
  );

  final LoanerDao _dao;
  final LoanerApi _api;
  final SyncEngine _engine;
  final ConnectivityService _connectivity;

  @override
  Stream<List<LoanerModel>> watchLoaners({
    String searchQuery = '',
    CustomerModel? customerFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _dao.watchLoaners(
      searchQuery: searchQuery,
      customerFilter: customerFilter,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  Future<bool> hasCachedLoaners({
    String searchQuery = '',
    CustomerModel? customerFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _dao.hasCachedLoaners(
      searchQuery: searchQuery,
      customerFilter: customerFilter,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  Future<Result<PaginatedResponse<LoanerModel>>> refreshLoaners({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String? customer,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (!await _connectivity.isOnline) {
      return const Err(AppException('Offline - showing cached loaners.'));
    }

    final result = await _api.fetchLoaners(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
      customer: customer,
      fromDate: fromDate,
      toDate: toDate,
    );

    if (result case Ok(:final value)) {
      await _dao.cacheServerLoaners(value.items);
    }

    return result;
  }

  @override
  Future<Result<LoanerModel>> createLoaner(LoanerModel body) async {
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final local = body.copyWith(id: id, syncStatus: SyncStatus.pending);

    await _dao.insertPending(local);
    await _enqueue(local, SyncOperation.create, 'create');

    return _settle(local);
  }

  @override
  Future<Result<LoanerModel>> updateLoaner(LoanerModel body) async {
    final updatedAt = DateTime.now();
    final local = body.copyWith(
      updatedAt: updatedAt,
      syncStatus: SyncStatus.pending,
      isDeleted: false,
    );

    await _dao.replace(local, SyncStatus.pending);
    await _enqueue(
      local,
      SyncOperation.update,
      'update:${updatedAt.microsecondsSinceEpoch}',
    );

    return _settle(local);
  }

  @override
  Future<Result<void>> deleteLoaner(LoanerModel body) async {
    await _dao.markDeletedPending(body.id);
    await _enqueue(body, SyncOperation.delete, 'delete');

    if (await _connectivity.isOnline) await _engine.drain();
    return const Ok<void>(null);
  }

  @override
  Future<void> syncPendingChanges() async {
    if (!await _connectivity.isOnline) return;
    await _engine.drain();
  }

  Future<void> _enqueue(
    LoanerModel loaner,
    SyncOperation operation,
    String keySuffix,
  ) {
    final customerId = loaner.customerId;
    return _engine.enqueue(
      entityType: SyncEntityType.loaner,
      localId: '${loaner.id}',
      operation: operation,
      idempotencyKey: 'loaner:${loaner.id}:$keySuffix',
      // A loan recorded against a customer created offline must not reach
      // the server before that customer exists. Same rule as a shop item
      // under an offline category.
      dependsOnLocalId:
          customerId != null && customerId < 0 ? '$customerId' : null,
    );
  }

  /// See `DefaultShopRepository._settle`.
  Future<Result<LoanerModel>> _settle(LoanerModel local) async {
    if (!await _connectivity.isOnline) return Ok(local);

    await _engine.drain();
    final after = await _dao.findById(local.id);
    return Ok(after ?? local.copyWith(syncStatus: SyncStatus.synced));
  }
}

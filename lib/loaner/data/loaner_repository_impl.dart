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

  static const _offlineWrite =
      'Saved offline. It will sync when you are back online.';
  static const _offlineDelete =
      'Deleted offline. It will sync when you are back online.';

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
  Future<ApiResponse<PaginatedResponse<LoanerModel>>> refreshLoaners({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String? customer,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (!await _connectivity.isOnline) {
      return ApiResponse(
        success: false,
        message: 'Offline - showing cached loaners.',
      );
    }

    final response = await _api.fetchLoaners(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
      customer: customer,
      fromDate: fromDate,
      toDate: toDate,
    );

    final data = response.data;
    if (response.success && data != null) {
      await _dao.cacheServerLoaners(data.items);
    }

    return response;
  }

  @override
  Future<ApiResponse<LoanerModel?>> createLoaner(LoanerModel body) async {
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final local = body.copyWith(id: id, syncStatus: SyncStatus.pending);

    await _dao.insertPending(local);
    await _enqueue(local, SyncOperation.create, 'create');

    return _afterLocalWrite(data: local, offlineMessage: _offlineWrite);
  }

  @override
  Future<ApiResponse<LoanerModel?>> updateLoaner(LoanerModel body) async {
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

    return _afterLocalWrite(
      data: body,
      offlineData: local,
      offlineMessage: _offlineWrite,
    );
  }

  @override
  Future<ApiResponse<dynamic>> deleteLoaner(LoanerModel body) async {
    await _dao.markDeletedPending(body.id);
    await _enqueue(body, SyncOperation.delete, 'delete');

    return _afterLocalWrite<dynamic>(
      data: null,
      offlineMessage: _offlineDelete,
    );
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

  Future<ApiResponse<T>> _afterLocalWrite<T>({
    required T data,
    required String offlineMessage,
    T? offlineData,
  }) async {
    if (await _connectivity.isOnline) {
      await _engine.drain();
      return ApiResponse(success: true, data: data);
    }

    return ApiResponse(
      success: true,
      data: offlineData ?? data,
      message: offlineMessage,
    );
  }
}

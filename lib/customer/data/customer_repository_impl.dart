import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Local-first customer writes, queued through the app's one outbox.
class DefaultCustomerRepository implements CustomerRepository {
  const DefaultCustomerRepository(
    this._dao,
    this._api,
    this._engine,
    this._connectivity,
  );

  final CustomerDao _dao;
  final CustomerApi _api;
  final SyncEngine _engine;
  final ConnectivityService _connectivity;

  static const _offlineWrite =
      'Saved offline. It will sync when you are back online.';
  static const _offlineDelete =
      'Deleted offline. It will sync when you are back online.';

  @override
  Stream<List<CustomerModel>> watchCustomers() => _dao.watchCustomers();

  @override
  Future<bool> hasCachedCustomers() => _dao.hasCachedCustomers();

  @override
  Future<ApiResponse<PaginatedResponse<CustomerModel>>> refreshCustomers({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) async {
    if (!await _connectivity.isOnline) {
      return ApiResponse(
        success: false,
        message: 'Offline - showing cached customers.',
      );
    }

    final response = await _api.fetchCustomers(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
      categoryFilter: categoryFilter,
    );

    final data = response.data;
    if (response.success && data != null) {
      await _dao.cacheServerCustomers(data.items);
    }

    return response;
  }

  @override
  Future<ApiResponse<CustomerModel?>> createCustomer(CustomerModel body) async {
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final local = body.copyWith(id: id, syncStatus: SyncStatus.pending);

    await _dao.insertPending(local);
    await _enqueue(local, SyncOperation.create, 'create');

    return _afterLocalWrite(data: local, offlineMessage: _offlineWrite);
  }

  @override
  Future<ApiResponse<CustomerModel?>> updateCustomer(CustomerModel body) async {
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
  Future<ApiResponse<dynamic>> deleteCustomer(CustomerModel body) async {
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
    CustomerModel customer,
    SyncOperation operation,
    String keySuffix,
  ) {
    return _engine.enqueue(
      entityType: SyncEntityType.customer,
      localId: '${customer.id}',
      operation: operation,
      idempotencyKey: 'customer:${customer.id}:$keySuffix',
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

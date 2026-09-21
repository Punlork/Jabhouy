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

  @override
  Stream<List<CustomerModel>> watchCustomers() => _dao.watchCustomers();

  @override
  Future<bool> hasCachedCustomers() => _dao.hasCachedCustomers();

  @override
  Future<Result<PaginatedResponse<CustomerModel>>> refreshCustomers({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) async {
    if (!await _connectivity.isOnline) {
      return const Err(AppException('Offline - showing cached customers.'));
    }

    final result = await _api.fetchCustomers(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
      categoryFilter: categoryFilter,
    );

    if (result case Ok(:final value)) {
      await _dao.cacheServerCustomers(value.items);
    }

    return result;
  }

  @override
  Future<Result<CustomerModel>> createCustomer(CustomerModel body) async {
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final local = body.copyWith(id: id, syncStatus: SyncStatus.pending);

    await _dao.insertPending(local);
    await _enqueue(local, SyncOperation.create, 'create');

    return _settle(local);
  }

  @override
  Future<Result<CustomerModel>> updateCustomer(CustomerModel body) async {
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
  Future<Result<void>> deleteCustomer(CustomerModel body) async {
    await _dao.markDeletedPending(body.id);
    await _enqueue(body, SyncOperation.delete, 'delete');

    if (await _connectivity.isOnline) await _engine.drain();
    return const Ok<void>(null);
  }

  @override
  Future<void> cacheCustomers(List<CustomerModel> customers) =>
      _dao.cacheServerCustomers(customers);

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

  /// See `DefaultShopRepository._settle`.
  Future<Result<CustomerModel>> _settle(CustomerModel local) async {
    if (!await _connectivity.isOnline) return Ok(local);

    await _engine.drain();
    final after = await _dao.findById(local.id);
    return Ok(after ?? local.copyWith(syncStatus: SyncStatus.synced));
  }
}

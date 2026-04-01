import 'package:drift/drift.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/customer/customer.dart';

class CustomerService extends BaseService {
  CustomerService(super.apiService, this._db, this._connectivityService);

  final AppDatabase _db;
  final ConnectivityService _connectivityService;

  @override
  String get basePath => '/customers';

  Stream<List<CustomerModel>> watchCustomers() {
    return (_db.select(_db.customers)..where((t) => t.isDeleted.equals(false)))
        .watch()
        .map((rows) {
      return rows
          .map(
            (row) => CustomerModel(
              id: row.id,
              name: row.name,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
              syncStatus: row.syncStatus,
              isDeleted: row.isDeleted,
            ),
          )
          .toList();
    });
  }

  Future<void> syncPendingChanges() async {
    if (!await _connectivityService.isOnline) {
      return;
    }

    final pendingItems = await (_db.select(_db.customers)
          ..where((t) => t.syncStatus.equals(1)))
        .get();

    for (final item in pendingItems) {
      try {
        final model = CustomerModel(
          id: item.id,
          name: item.name,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          syncStatus: item.syncStatus,
          isDeleted: item.isDeleted,
        );

        ApiResponse<CustomerModel?> response;
        if (item.isDeleted) {
          await deleteCustomer(model, localOnly: false);
          response = ApiResponse(success: true);
        } else if (item.id < 0) {
          response = await createCustomer(model, localOnly: false);
        } else {
          response = await updateCustomer(model, localOnly: false);
        }

        if (!response.success) {
          await (_db.update(_db.customers)..where((t) => t.id.equals(item.id)))
              .write(
            const CustomersCompanion(syncStatus: Value(2)),
          );
        }
      } catch (_) {
        await (_db.update(_db.customers)..where((t) => t.id.equals(item.id)))
            .write(
          const CustomersCompanion(syncStatus: Value(2)),
        );
      }
    }
  }

  Future<bool> hasCachedCustomers() async {
    final query = _db.select(_db.customers)
      ..where((t) => t.isDeleted.equals(false))
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  Future<ApiResponse<PaginatedResponse<CustomerModel>>> getCustomers({
    int? page = 1,
    int? limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) async {
    if (!await _connectivityService.isOnline) {
      return ApiResponse(
        success: false,
        message: 'Offline - showing cached customers.',
      );
    }

    final response = await get<PaginatedResponse<CustomerModel>>(
      '',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'name': searchQuery,
        'category': categoryFilter,
      }..removeWhere(
          (key, value) => value.toString().isEmpty,
        ),
      parser: (value) => value is Map
          ? PaginatedResponse.fromJson(
              value as Map<String, dynamic>,
              CustomerModel.fromJson,
            )
          : PaginatedResponse(
              items: [],
              pagination: Pagination(),
            ),
    );

    if (response.success && response.data != null) {
      final customers = response.data!.items;
      await _db.batch((batch) {
        batch.insertAll(
          _db.customers,
          customers.map(
            (c) => CustomersCompanion.insert(
              id: Value(c.id),
              name: c.name,
              createdAt: Value(c.createdAt),
              updatedAt: Value(c.updatedAt),
              syncStatus: const Value(0),
              isDeleted: const Value(false),
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    return response;
  }

  Future<ApiResponse<CustomerModel?>> createCustomer(
    CustomerModel body, {
    bool localOnly = true,
  }) async {
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final localItem = body.copyWith(id: id, syncStatus: 1);

    await _db.into(_db.customers).insert(
          CustomersCompanion.insert(
            id: Value(localItem.id),
            name: localItem.name,
            createdAt: Value(localItem.createdAt ?? DateTime.now()),
            updatedAt: Value(localItem.updatedAt ?? DateTime.now()),
            syncStatus: const Value(1),
          ),
          mode: InsertMode.insertOrReplace,
        );

    if (localOnly) {
      if (await _connectivityService.isOnline) {
        await syncPendingChanges();
        return ApiResponse(success: true, data: localItem);
      }

      return ApiResponse(
        success: true,
        data: localItem,
        message: 'Saved offline. It will sync when you are back online.',
      );
    }

    final response = await post(
      '',
      bodyParser: body.toJson,
      parser: (value) => value is Map
          ? CustomerModel.fromJson(
              value as Map<String, dynamic>,
            )
          : null,
    );

    if (response.success && response.data != null) {
      final c = response.data!;
      await (_db.delete(_db.customers)..where((t) => t.id.equals(localItem.id)))
          .go();
      await _db.into(_db.customers).insert(
            CustomersCompanion.insert(
              id: Value(c.id),
              name: c.name,
              createdAt: Value(c.createdAt),
              updatedAt: Value(c.updatedAt),
              syncStatus: const Value(0),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    return response;
  }

  Future<ApiResponse<CustomerModel?>> updateCustomer(
    CustomerModel body, {
    bool localOnly = true,
  }) async {
    final updatedAt = DateTime.now();

    await _db.update(_db.customers).replace(
          Customer(
            id: body.id,
            name: body.name,
            createdAt: body.createdAt,
            updatedAt: updatedAt,
            syncStatus: 1,
            isDeleted: false,
          ),
        );

    if (localOnly) {
      if (await _connectivityService.isOnline) {
        await syncPendingChanges();
        return ApiResponse(success: true, data: body);
      }

      return ApiResponse(
        success: true,
        data: body.copyWith(syncStatus: 1, updatedAt: updatedAt),
        message: 'Saved offline. It will sync when you are back online.',
      );
    }

    final response = await put(
      '/${body.id}',
      bodyParser: body.toJson,
      parser: (value) => value is Map
          ? CustomerModel.fromJson(
              value as Map<String, dynamic>,
            )
          : null,
    );

    if (response.success && response.data != null) {
      final c = response.data!;
      await _db.update(_db.customers).replace(
            Customer(
              id: c.id,
              name: c.name,
              createdAt: c.createdAt,
              updatedAt: c.updatedAt,
              syncStatus: 0,
              isDeleted: false,
            ),
          );
    }

    return response;
  }

  Future<ApiResponse<dynamic>> deleteCustomer(
    CustomerModel body, {
    bool localOnly = true,
  }) async {
    await (_db.update(_db.customers)..where((t) => t.id.equals(body.id))).write(
      const CustomersCompanion(
        isDeleted: Value(true),
        syncStatus: Value(1),
      ),
    );

    if (localOnly) {
      if (await _connectivityService.isOnline) {
        await syncPendingChanges();
        return ApiResponse(success: true);
      }

      return ApiResponse(
        success: true,
        message: 'Deleted offline. It will sync when you are back online.',
      );
    }

    final response = await delete<dynamic>('/${body.id}');

    if (response.success) {
      await (_db.delete(_db.customers)..where((t) => t.id.equals(body.id)))
          .go();
    }

    return response;
  }
}

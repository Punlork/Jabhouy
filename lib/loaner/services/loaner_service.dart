import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/loaner/loaner.dart';

class LoanerService extends BaseService {
  LoanerService(super.apiService, this._db);
  final AppDatabase _db;

  @override
  String get basePath => '/loans';

  String _formatToRFC3339Date(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? _encodeCustomer(CustomerModel? customer) {
    if (customer == null) return null;
    return jsonEncode({
      'id': customer.id,
      'name': customer.name,
      if (customer.createdAt != null)
        'createdAt': customer.createdAt!.toIso8601String(),
      if (customer.updatedAt != null)
        'updatedAt': customer.updatedAt!.toIso8601String(),
      'syncStatus': customer.syncStatus,
      'isDeleted': customer.isDeleted,
    });
  }

  CustomerModel? _decodeCustomer(String? rawCustomer) {
    if (rawCustomer == null || rawCustomer.isEmpty) return null;

    final decoded = jsonDecode(rawCustomer);
    if (decoded is! Map<String, dynamic>) return null;
    return CustomerModel.fromJson(decoded);
  }

  CustomerModel? _mapCustomer(Customer? customer) {
    if (customer == null || customer.isDeleted) return null;
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
      syncStatus: customer.syncStatus,
      isDeleted: customer.isDeleted,
    );
  }

  Future<void> _upsertCustomers(Iterable<CustomerModel?> customers) async {
    final uniqueCustomers = <int, CustomerModel>{};
    for (final customer in customers) {
      if (customer == null) continue;
      final value = customer;
      uniqueCustomers[value.id] = value;
    }

    if (uniqueCustomers.isEmpty) return;

    await _db.batch((batch) {
      batch.insertAll(
        _db.customers,
        uniqueCustomers.values
            .map(
              (customer) => CustomersCompanion.insert(
                id: Value(customer.id),
                name: customer.name,
                createdAt: Value(customer.createdAt),
                updatedAt: Value(customer.updatedAt),
                syncStatus: Value(customer.syncStatus),
                isDeleted: Value(customer.isDeleted),
              ),
            )
            .toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Stream<List<LoanerModel>> watchLoaners() {
    final query = _db.select(_db.loaners).join(
      [
        leftOuterJoin(
          _db.customers,
          _db.customers.id.equalsExp(_db.loaners.customerId) &
              _db.customers.isDeleted.equals(false),
        ),
      ],
    )
      ..where(_db.loaners.isDeleted.equals(false))
      ..orderBy([
        OrderingTerm.desc(_db.loaners.createdAt),
        OrderingTerm.desc(_db.loaners.id),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final loaner = row.readTable(_db.loaners);
        final customer = row.readTableOrNull(_db.customers);

        return LoanerModel(
          id: loaner.id,
          amount: loaner.amount,
          note: loaner.note,
          customerId: loaner.customerId,
          isPaid: loaner.isPaid,
          createdAt: loaner.createdAt,
          updatedAt: loaner.updatedAt,
          syncStatus: loaner.syncStatus,
          isDeleted: loaner.isDeleted,
          customer: _decodeCustomer(loaner.customer) ?? _mapCustomer(customer),
        );
      }).toList();
    });
  }

  Future<void> syncPendingChanges() async {
    final pendingItems = await (_db.select(_db.loaners)
          ..where((t) => t.syncStatus.equals(1)))
        .get();

    for (final item in pendingItems) {
      try {
        final model = LoanerModel(
          id: item.id,
          amount: item.amount,
          note: item.note,
          customerId: item.customerId,
          isPaid: item.isPaid,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          syncStatus: item.syncStatus,
          isDeleted: item.isDeleted,
          customer: _decodeCustomer(item.customer),
        );

        ApiResponse<LoanerModel?> response;
        if (item.isDeleted) {
          await deleteLoaner(model, localOnly: false);
          response = ApiResponse(success: true);
        } else if (item.id < 0) {
          response = await createLoaner(model, localOnly: false);
        } else {
          response = await updateLoaner(model, localOnly: false);
        }

        if (response.success) {}
      } catch (e) {
        await (_db.update(_db.loaners)..where((t) => t.id.equals(item.id)))
            .write(
          const LoanersCompanion(syncStatus: Value(2)),
        );
      }
    }
  }

  Future<ApiResponse<PaginatedResponse<LoanerModel>>> getLoaners({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String? customer,
    DateTime? toDate,
    DateTime? fromDate,
  }) async {
    final response = await get<PaginatedResponse<LoanerModel>>(
      '',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'name': searchQuery,
        'customer': customer,
        'to': toDate != null ? _formatToRFC3339Date(toDate) : null,
        'from': fromDate != null ? _formatToRFC3339Date(fromDate) : null,
      }..removeWhere(
          (key, value) => value.toString().isEmpty || value == null,
        ),
      parser: (value) => value is Map
          ? PaginatedResponse.fromJson(
              value as Map<String, dynamic>,
              LoanerModel.fromJson,
            )
          : PaginatedResponse(
              items: [],
              pagination: Pagination(),
            ),
    );

    if (response.success && response.data != null) {
      final items = response.data!.items;
      final customers = items.map((item) => item.customer);

      await _db.batch((batch) {
        final uniqueCustomers = <int, CustomerModel>{};
        for (final customer in customers) {
          if (customer == null) continue;
          final value = customer;
          uniqueCustomers[value.id] = value;
        }

        if (uniqueCustomers.isNotEmpty) {
          batch.insertAll(
            _db.customers,
            uniqueCustomers.values
                .map(
                  (customer) => CustomersCompanion.insert(
                    id: Value(customer.id),
                    name: customer.name,
                    createdAt: Value(customer.createdAt),
                    updatedAt: Value(customer.updatedAt),
                    syncStatus: Value(customer.syncStatus),
                    isDeleted: Value(customer.isDeleted),
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
        }

        batch.insertAll(
          _db.loaners,
          items.map(
            (l) => LoanersCompanion.insert(
              id: Value(l.id),
              amount: l.amount,
              note: Value(l.note),
              customerId: Value(l.customerId),
              customer: Value(_encodeCustomer(l.customer)),
              isPaid: Value(l.isPaid),
              createdAt: l.createdAt,
              updatedAt: Value(l.updatedAt),
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

  Future<ApiResponse<LoanerModel?>> createLoaner(
    LoanerModel body, {
    bool localOnly = true,
  }) async {
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final localItem = body.copyWith(id: id, syncStatus: 1);

    await _db.into(_db.loaners).insert(
          LoanersCompanion.insert(
            id: Value(localItem.id),
            amount: localItem.amount,
            note: Value(localItem.note),
            customerId: Value(localItem.customerId),
            customer: Value(_encodeCustomer(localItem.customer)),
            isPaid: Value(localItem.isPaid),
            createdAt: localItem.createdAt,
            updatedAt: Value(localItem.updatedAt),
            syncStatus: const Value(1),
          ),
          mode: InsertMode.insertOrReplace,
        );

    if (localOnly) {
      await syncPendingChanges();
      return ApiResponse(success: true, data: localItem);
    }

    final response = await post(
      '',
      bodyParser: body.toJson,
      parser: (value) => value is Map
          ? LoanerModel.fromJson(
              value as Map<String, dynamic>,
            )
          : null,
    );

    if (response.success && response.data != null) {
      final l = response.data!;
      await _upsertCustomers([l.customer]);
      await (_db.delete(_db.loaners)..where((t) => t.id.equals(localItem.id)))
          .go();
      await _db.into(_db.loaners).insert(
            LoanersCompanion.insert(
              id: Value(l.id),
              amount: l.amount,
              note: Value(l.note),
              customerId: Value(l.customerId),
              customer: Value(_encodeCustomer(l.customer)),
              isPaid: Value(l.isPaid),
              createdAt: l.createdAt,
              updatedAt: Value(l.updatedAt),
              syncStatus: const Value(0),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    return response;
  }

  Future<ApiResponse<LoanerModel?>> updateLoaner(
    LoanerModel body, {
    bool localOnly = true,
  }) async {
    await _db.update(_db.loaners).replace(
          Loaner(
            id: body.id,
            amount: body.amount,
            note: body.note,
            customerId: body.customerId,
            customer: _encodeCustomer(body.customer),
            isPaid: body.isPaid,
            createdAt: body.createdAt,
            updatedAt: DateTime.now(),
            syncStatus: 1,
            isDeleted: false,
          ),
        );

    if (localOnly) {
      await syncPendingChanges();
      return ApiResponse(success: true, data: body);
    }

    final response = await put(
      '/${body.id}',
      bodyParser: body.toJson,
      parser: (value) => value is Map
          ? LoanerModel.fromJson(
              value as Map<String, dynamic>,
            )
          : null,
    );

    if (response.success && response.data != null) {
      final l = response.data!;
      await _upsertCustomers([l.customer]);
      await _db.update(_db.loaners).replace(
            Loaner(
              id: l.id,
              amount: l.amount,
              note: l.note,
              customerId: l.customerId,
              customer: _encodeCustomer(l.customer),
              isPaid: l.isPaid,
              createdAt: l.createdAt,
              updatedAt: l.updatedAt,
              syncStatus: 0,
              isDeleted: false,
            ),
          );
    }

    return response;
  }

  Future<ApiResponse<dynamic>> deleteLoaner(
    LoanerModel body, {
    bool localOnly = true,
  }) async {
    await (_db.update(_db.loaners)..where((t) => t.id.equals(body.id))).write(
      const LoanersCompanion(
        isDeleted: Value(true),
        syncStatus: Value(1),
      ),
    );

    if (localOnly) {
      await syncPendingChanges();
      return ApiResponse(success: true);
    }

    final response = await delete<dynamic>('/${body.id}');

    if (response.success) {
      await (_db.delete(_db.loaners)..where((t) => t.id.equals(body.id))).go();
    }

    return response;
  }
}

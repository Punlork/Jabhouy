import 'package:drift/drift.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/shop/shop.dart';

class CategoryService extends BaseService {
  CategoryService(super.apiService, this._db, this._connectivityService);

  final AppDatabase _db;
  final ConnectivityService _connectivityService;

  @override
  String get basePath => '/categories';

  Stream<List<CategoryItemModel>> watchCategories() {
    return (_db.select(_db.categories)..where((t) => t.isDeleted.equals(false))).watch().map((rows) {
      return rows
          .map(
            (row) => CategoryItemModel(
              id: row.id,
              name: row.name,
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

    final pendingItems = await (_db.select(_db.categories)..where((t) => t.syncStatus.equals(1))).get();

    for (final item in pendingItems) {
      try {
        final model = CategoryItemModel(
          id: item.id,
          name: item.name,
          syncStatus: item.syncStatus,
          isDeleted: item.isDeleted,
        );

        ApiResponse<CategoryItemModel?> response;
        if (item.isDeleted) {
          await deleteCategory(model, localOnly: false);
          response = ApiResponse(success: true);
        } else if (item.id < 0) {
          response = await createCategory(model, localOnly: false);
        } else {
          response = await updateCategory(model, localOnly: false);
        }

        if (!response.success) {
          await (_db.update(_db.categories)..where((t) => t.id.equals(item.id))).write(
            const CategoriesCompanion(
              syncStatus: Value(2),
            ),
          );
        }
      } catch (_) {
        await (_db.update(_db.categories)..where((t) => t.id.equals(item.id))).write(
          const CategoriesCompanion(syncStatus: Value(2)),
        );
      }
    }
  }

  Future<ApiResponse<List<CategoryItemModel>>> getCategory() async {
    if (!await _connectivityService.isOnline) {
      return ApiResponse(
        success: false,
        message: 'Offline - showing cached data.',
      );
    }

    final response = await get<List<CategoryItemModel>>(
      '',
      parser: (value) {
        if (value is List) {
          return value
              .map(
                (e) => CategoryItemModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        return [];
      },
    );

    if (response.success && response.data != null) {
      final categories = response.data!;
      await _db.batch((batch) {
        batch.insertAll(
          _db.categories,
          categories.map(
            (c) => CategoriesCompanion.insert(
              id: Value(c.id),
              name: c.name,
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

  Future<ApiResponse<CategoryItemModel?>> createCategory(
    CategoryItemModel body, {
    bool localOnly = true,
  }) async {
    final id = body.id == 0 ? -(DateTime.now().millisecondsSinceEpoch % 1000000) : body.id;
    final localItem = body.copyWith(id: id, syncStatus: 1);

    await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            id: Value(localItem.id),
            name: localItem.name,
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
          ? CategoryItemModel.fromJson(
              value as Map<String, dynamic>,
            )
          : null,
    );

    if (response.success && response.data != null) {
      final c = response.data!;
      await (_db.delete(_db.categories)..where((t) => t.id.equals(localItem.id))).go();
      await _db.into(_db.categories).insert(
            CategoriesCompanion.insert(
              id: Value(c.id),
              name: c.name,
              syncStatus: const Value(0),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    return response;
  }

  Future<ApiResponse<CategoryItemModel?>> updateCategory(
    CategoryItemModel body, {
    bool localOnly = true,
  }) async {
    await _db.update(_db.categories).replace(
          Category(
            id: body.id,
            name: body.name,
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
        data: body.copyWith(syncStatus: 1),
        message: 'Saved offline. It will sync when you are back online.',
      );
    }

    final response = await put(
      '/${body.id}',
      bodyParser: body.toJson,
      parser: (value) => value is Map
          ? CategoryItemModel.fromJson(
              value as Map<String, dynamic>,
            )
          : null,
    );

    if (response.success && response.data != null) {
      final c = response.data!;
      await _db.update(_db.categories).replace(
            Category(
              id: c.id,
              name: c.name,
              syncStatus: 0,
              isDeleted: false,
            ),
          );
    }

    return response;
  }

  Future<ApiResponse<dynamic>> deleteCategory(
    CategoryItemModel body, {
    bool localOnly = true,
  }) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(body.id))).write(
      const CategoriesCompanion(
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

    final response = await delete<dynamic>(
      '/${body.id}',
    );

    if (response.success) {
      await (_db.delete(_db.categories)..where((t) => t.id.equals(body.id))).go();
    }

    return response;
  }
}

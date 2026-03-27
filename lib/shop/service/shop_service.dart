import 'package:drift/drift.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/shop/shop.dart';

class ShopService extends BaseService {
  ShopService(super.apiService, this._db);
  final AppDatabase _db;

  @override
  String get basePath => '/items';

  Stream<List<ShopItemModel>> watchShopItems({
    String searchQuery = '',
    CategoryItemModel? categoryFilter,
  }) {
    final query = _db.select(_db.shopItems)..where((t) => t.isDeleted.equals(false));

    if (searchQuery.isNotEmpty) {
      query.where((t) => t.name.contains(searchQuery) | t.note.contains(searchQuery));
    }

    if (categoryFilter != null) {
      query.where((t) => t.categoryId.equals(categoryFilter.id));
    }

    return query.watch().map((rows) {
      return rows
          .map(
            (row) => ShopItemModel(
              id: row.id,
              name: row.name,
              defaultPrice: row.defaultPrice,
              customerPrice: row.customerPrice,
              sellerPrice: row.sellerPrice,
              note: row.note,
              imageUrl: row.imageUrl,
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
    final pendingItems = await (_db.select(_db.shopItems)..where((t) => t.syncStatus.equals(1))).get();

    for (final item in pendingItems) {
      try {
        final model = ShopItemModel(
          id: item.id,
          name: item.name,
          defaultPrice: item.defaultPrice,
          customerPrice: item.customerPrice,
          sellerPrice: item.sellerPrice,
          note: item.note,
          imageUrl: item.imageUrl,
          syncStatus: item.syncStatus,
          isDeleted: item.isDeleted,
        );

        ApiResponse<ShopItemModel?> response;
        if (item.isDeleted) {
          await deleteShopItem(model, localOnly: false);
          response = ApiResponse(success: true);
        } else if (item.id < 0) {
          // New item created offline
          response = await createShopItem(model, localOnly: false);
        } else {
          // Existing item updated offline
          response = await updateShopItem(model, localOnly: false);
        }

        if (response.success) {
          // Handled in create/update/delete methods if localOnly is false
        }
      } catch (e) {
        // Log error and maybe set syncStatus to error (2)
        await (_db.update(_db.shopItems)..where((t) => t.id.equals(item.id))).write(
          const ShopItemsCompanion(syncStatus: Value(2)),
        );
      }
    }
  }

  Future<ApiResponse<PaginatedResponse<ShopItemModel>>> getShopItems({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) async {
    final response = await get(
      '',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'search': searchQuery,
        'category': categoryFilter,
      }..removeWhere(
          (key, value) => value.toString().isEmpty,
        ),
      parser: (value) {
        if (value is Map) {
          return PaginatedResponse.fromJson(
            value as Map<String, dynamic>,
            ShopItemModel.fromJson,
          );
        }
        return PaginatedResponse<ShopItemModel>(
          items: [],
          pagination: Pagination(
            total: 0,
            totalPage: 1,
          ),
        );
      },
    );

    if (response.success && response.data != null) {
      final items = response.data!.items;
      await _db.batch((batch) {
        batch.insertAll(
          _db.shopItems,
          items.map(
            (i) => ShopItemsCompanion.insert(
              id: Value(i.id),
              name: i.name,
              defaultPrice: Value(i.defaultPrice),
              customerPrice: Value(i.customerPrice),
              sellerPrice: Value(i.sellerPrice),
              note: Value(i.note),
              imageUrl: Value(i.imageUrl),
              categoryId: Value(i.category?.id),
              createdAt: Value(i.createdAt),
              updatedAt: Value(i.updatedAt),
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

  Future<ApiResponse<ShopItemModel?>> createShopItem(
    ShopItemModel body, {
    bool localOnly = true,
  }) async {
    // Generate temporary ID if needed
    final id = body.id == 0 ? -(DateTime.now().millisecondsSinceEpoch % 1000000) : body.id;
    final localItem = body.copyWith(id: id, syncStatus: 1);

    await _db.into(_db.shopItems).insert(
          ShopItemsCompanion.insert(
            id: Value(localItem.id),
            name: localItem.name,
            defaultPrice: Value(localItem.defaultPrice),
            customerPrice: Value(localItem.customerPrice),
            sellerPrice: Value(localItem.sellerPrice),
            note: Value(localItem.note),
            imageUrl: Value(localItem.imageUrl),
            categoryId: Value(localItem.category?.id),
            createdAt: Value(localItem.createdAt ?? DateTime.now()),
            updatedAt: Value(localItem.updatedAt ?? DateTime.now()),
            syncStatus: const Value(1),
          ),
          mode: InsertMode.insertOrReplace,
        );

    if (localOnly) {
      await syncPendingChanges(); // Fire and forget
      return ApiResponse(success: true, data: localItem);
    }

    final response = await post(
      '',
      bodyParser: body.toJson,
      parser: (value) => value is Map
          ? ShopItemModel.fromJson(
              value as Map<String, dynamic>,
            )
          : null,
    );

    if (response.success && response.data != null) {
      final i = response.data!;
      // Delete temporary local item and insert real one
      await (_db.delete(_db.shopItems)..where((t) => t.id.equals(localItem.id))).go();
      await _db.into(_db.shopItems).insert(
            ShopItemsCompanion.insert(
              id: Value(i.id),
              name: i.name,
              defaultPrice: Value(i.defaultPrice),
              customerPrice: Value(i.customerPrice),
              sellerPrice: Value(i.sellerPrice),
              note: Value(i.note),
              imageUrl: Value(i.imageUrl),
              categoryId: Value(i.category?.id),
              createdAt: Value(i.createdAt),
              updatedAt: Value(i.updatedAt),
              syncStatus: const Value(0),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    return response;
  }

  Future<ApiResponse<ShopItemModel?>> updateShopItem(
    ShopItemModel body, {
    bool localOnly = true,
  }) async {
    await _db.update(_db.shopItems).replace(
          ShopItem(
            id: body.id,
            name: body.name,
            defaultPrice: body.defaultPrice,
            customerPrice: body.customerPrice,
            sellerPrice: body.sellerPrice,
            note: body.note,
            imageUrl: body.imageUrl,
            categoryId: body.category?.id,
            createdAt: body.createdAt,
            updatedAt: DateTime.now(),
            syncStatus: 1,
            isDeleted: false,
          ),
        );

    if (localOnly) {
      await syncPendingChanges(); // Fire and forget
      return ApiResponse(success: true, data: body);
    }

    final response = await put(
      '/${body.id}',
      bodyParser: body.toJson,
      parser: (value) => value is Map
          ? ShopItemModel.fromJson(
              value as Map<String, dynamic>,
            )
          : null,
    );

    if (response.success && response.data != null) {
      final i = response.data!;
      await _db.update(_db.shopItems).replace(
            ShopItem(
              id: i.id,
              name: i.name,
              defaultPrice: i.defaultPrice,
              customerPrice: i.customerPrice,
              sellerPrice: i.sellerPrice,
              note: i.note,
              imageUrl: i.imageUrl,
              categoryId: i.category?.id,
              createdAt: i.createdAt,
              updatedAt: i.updatedAt,
              syncStatus: 0,
              isDeleted: false,
            ),
          );
    }

    return response;
  }

  Future<ApiResponse<dynamic>> deleteShopItem(
    ShopItemModel body, {
    bool localOnly = true,
  }) async {
    await (_db.update(_db.shopItems)..where((t) => t.id.equals(body.id))).write(
      const ShopItemsCompanion(
        isDeleted: Value(true),
        syncStatus: Value(1),
      ),
    );

    if (localOnly) {
      await syncPendingChanges(); // Fire and forget
      return ApiResponse(success: true);
    }

    final response = await delete<ShopItemModel?>('/${body.id}');

    if (response.success) {
      await (_db.delete(_db.shopItems)..where((t) => t.id.equals(body.id))).go();
    }

    return response;
  }
}

import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Every HTTP call the shop feature makes, and nothing else. It does not
/// touch the database and does not decide when a call happens — the
/// repository owns that.
class ShopApi extends BaseService {
  ShopApi(super.apiService);

  @override
  String get basePath => '/items';

  Future<ApiResponse<PaginatedResponse<ShopItemModel>>> fetchItems({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) {
    return get(
      '',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'search': searchQuery,
        'category': categoryFilter,
      }..removeWhere((key, value) => value.toString().isEmpty),
      parser: (value) {
        if (value is Map) {
          return PaginatedResponse.fromJson(
            value as Map<String, dynamic>,
            ShopItemModel.fromJson,
          );
        }
        return PaginatedResponse<ShopItemModel>(
          items: [],
          pagination: Pagination(total: 0, totalPage: 1),
        );
      },
    );
  }

  Future<ApiResponse<ShopItemModel?>> createItem(ShopItemModel body) {
    return post('', bodyParser: body.toJson, parser: _parseItem);
  }

  Future<ApiResponse<ShopItemModel?>> updateItem(ShopItemModel body) {
    return put('/${body.id}', bodyParser: body.toJson, parser: _parseItem);
  }

  Future<ApiResponse<dynamic>> deleteItem(int id) {
    return delete<dynamic>('/$id');
  }

  ShopItemModel? _parseItem(dynamic value) {
    return value is Map
        ? ShopItemModel.fromJson(value as Map<String, dynamic>)
        : null;
  }
}

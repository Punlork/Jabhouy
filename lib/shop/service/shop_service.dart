import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

class ShopService extends BaseService {
  factory ShopService(ApiService apiService) => ShopService._(apiService);
  ShopService._(super.apiService);

  @override
  String get basePath => '/items';

  Future<ApiResponse<PaginatedResponse<ShopItemModel>>> getShopItems({
    int page = 1,
    int pageSize = 10,
    String searchQuery = '',
    String categoryFilter = 'All',
    String buyerFilter = 'All',
  }) {
    return get(
      '',
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'search': searchQuery,
      },
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
  }

  Future<ApiResponse<ShopItemModel?>> createShopItem(ShopItemModel body) => post(
        '',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? ShopItemModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<ShopItemModel?>> updateShopItem(ShopItemModel body) => put(
        '/${body.id}',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? ShopItemModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<dynamic>> deleteShopItem(ShopItemModel body) => delete(
        '/${body.id}',
      );
}

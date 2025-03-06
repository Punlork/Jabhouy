import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

class ShopService extends BaseService {
  factory ShopService(ApiService apiService) => ShopService._(apiService);
  ShopService._(super.apiService);

  @override
  String get basePath => '/items';

  Future<ApiResponse<List<ShopItemModel>>> getShopItems() {
    return get(
      '',
      parser: (value) => (value as List)
          .map(
            (item) => ShopItemModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
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

import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';

/// Every HTTP call the shop feature makes, and nothing else. It does not
/// touch the database and does not decide when a call happens — the
/// repository owns that.
class ShopApi extends BaseService {
  ShopApi(super.apiService);

  @override
  String get basePath => '/items';

  Future<Result<PaginatedResponse<ShopItemModel>>> fetchItems({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
    /// The background pull passes true: nobody is waiting on it, so a
    /// failure is logged by the engine instead of shown as a snackbar.
    bool quiet = false,
  }) async {
    final response = await get<PaginatedResponse<ShopItemModel>>(
      '',
      showSnackBar: !quiet,
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
        // No total: an unreadable reply must not look like a complete,
        // empty list, or a pull would delete every item.
        return PaginatedResponse<ShopItemModel>(
          items: [],
          pagination: Pagination(totalPage: 1),
        );
      },
    );
    return response.toResult();
  }

  Future<Result<ShopItemModel>> createItem(ShopItemModel body) async {
    final response =
        await post<ShopItemModel>('', bodyParser: body.toJson, parser: _parseItem);
    return response.toResult();
  }

  Future<Result<ShopItemModel>> updateItem(ShopItemModel body) async {
    final response = await put<ShopItemModel>(
      '/${body.id}',
      bodyParser: body.toJson,
      parser: _parseItem,
    );
    return response.toResult();
  }

  Future<Result<void>> deleteItem(int id) async {
    final response = await delete<dynamic>('/$id');
    return response.toVoidResult();
  }

  ShopItemModel _parseItem(dynamic value) {
    return ShopItemModel.fromJson(value as Map<String, dynamic>);
  }
}

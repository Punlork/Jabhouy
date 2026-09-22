import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';

/// Every HTTP call the category feature makes, and nothing else.
class CategoryApi extends BaseService {
  CategoryApi(super.apiService);

  @override
  String get basePath => '/categories';

  Future<Result<List<CategoryItemModel>>> fetchCategories() async {
    final response = await get<List<CategoryItemModel>>(
      '',
      parser: (value) {
        if (value is List) {
          return value
              .map((e) => CategoryItemModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
    return response.toResult();
  }

  Future<Result<CategoryItemModel>> createCategory(
    CategoryItemModel body,
  ) async {
    final response = await post<CategoryItemModel>(
      '',
      bodyParser: body.toJson,
      parser: _parse,
    );
    return response.toResult();
  }

  Future<Result<CategoryItemModel>> updateCategory(
    CategoryItemModel body,
  ) async {
    final response = await put<CategoryItemModel>(
      '/${body.id}',
      bodyParser: body.toJson,
      parser: _parse,
    );
    return response.toResult();
  }

  Future<Result<void>> deleteCategory(int id) async {
    final response = await delete<dynamic>('/$id');
    return response.toVoidResult();
  }

  CategoryItemModel _parse(dynamic value) {
    return CategoryItemModel.fromJson(value as Map<String, dynamic>);
  }
}

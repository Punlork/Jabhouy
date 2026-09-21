import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';

/// Every HTTP call the category feature makes, and nothing else.
class CategoryApi extends BaseService {
  CategoryApi(super.apiService);

  @override
  String get basePath => '/categories';

  Future<ApiResponse<List<CategoryItemModel>>> fetchCategories() {
    return get<List<CategoryItemModel>>(
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
  }

  Future<ApiResponse<CategoryItemModel?>> createCategory(
    CategoryItemModel body,
  ) {
    return post('', bodyParser: body.toJson, parser: _parse);
  }

  Future<ApiResponse<CategoryItemModel?>> updateCategory(
    CategoryItemModel body,
  ) {
    return put('/${body.id}', bodyParser: body.toJson, parser: _parse);
  }

  Future<ApiResponse<dynamic>> deleteCategory(int id) {
    return delete<dynamic>('/$id');
  }

  CategoryItemModel? _parse(dynamic value) {
    return value is Map
        ? CategoryItemModel.fromJson(value as Map<String, dynamic>)
        : null;
  }
}

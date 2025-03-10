import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

class CategoryService extends BaseService {
  factory CategoryService(ApiService apiService) => CategoryService._(apiService);
  CategoryService._(super.apiService);

  @override
  String get basePath => '/categories';

  Future<ApiResponse<List<CategoryItemModel>>> getCategory() {
    return get(
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
  }

  Future<ApiResponse<CategoryItemModel?>> createCategory(CategoryItemModel body) => post(
        '',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? CategoryItemModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<CategoryItemModel?>> updateCategory(CategoryItemModel body) => put(
        '/${body.id}',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? CategoryItemModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<dynamic>> deleteCategory(CategoryItemModel body) => delete(
        '/${body.id}',
      );
}

import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';

/// Every HTTP call the category feature makes, and nothing else.
class CategoryApi extends BaseService {
  CategoryApi(super.apiService);

  @override
  String get basePath => '/categories';

  Future<Result<List<CategoryItemModel>>> fetchCategories({
    /// The background pull passes true: nobody is waiting on it, so a
    /// failure is logged by the engine instead of shown as a snackbar.
    bool quiet = false,
  }) async {
    final response = await get<List<CategoryItemModel>>(
      '',
      showSnackBar: !quiet,
      parser: (value) {
        if (value is List) {
          return value
              .map((e) => CategoryItemModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // An error, not an empty list: a pull takes an empty list as "the
        // server has no categories" and deletes them all.
        throw const FormatException('Expected a list of categories');
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

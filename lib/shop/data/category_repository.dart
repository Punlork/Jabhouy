import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';

/// The seam the category bloc talks to.
///
/// Category earns no `logic/` layer: it has one field and no rules.
abstract class CategoryRepository {
  Stream<List<CategoryItemModel>> watchCategories();

  /// Pulls the category list from the server and caches it.
  Future<ApiResponse<List<CategoryItemModel>>> refreshCategories();

  Future<ApiResponse<CategoryItemModel?>> createCategory(
    CategoryItemModel body,
  );

  Future<ApiResponse<CategoryItemModel?>> updateCategory(
    CategoryItemModel body,
  );

  Future<ApiResponse<dynamic>> deleteCategory(CategoryItemModel body);
}

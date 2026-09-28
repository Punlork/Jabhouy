import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/src/models/category_model.dart';

/// The seam the category bloc talks to.
///
/// Category earns no `logic/` layer: it has one field and no rules.
/// Imports no Flutter, so `logic/` elsewhere may depend on it.
abstract class CategoryRepository {
  Stream<List<CategoryItemModel>> watchCategories();

  /// Pulls the category list from the server and caches it.
  Future<Result<List<CategoryItemModel>>> refreshCategories();

  Future<Result<CategoryItemModel>> createCategory(CategoryItemModel body);

  Future<Result<CategoryItemModel>> updateCategory(CategoryItemModel body);

  Future<Result<void>> deleteCategory(CategoryItemModel body);

  /// Pull-to-refresh with background sync: download every categories now,
  /// whatever the staleness window says.
  Future<void> pullLatest();
}

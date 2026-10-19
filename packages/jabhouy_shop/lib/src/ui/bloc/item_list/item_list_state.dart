part of 'item_list_cubit.dart';

@CopyWith()
class ItemListState extends Equatable {
  const ItemListState({
    this.loading = true,
    this.items = const [],
    this.categories = const [],
    this.missingCount = 0,
    this.query = '',
    this.categoryId,
    this.missingOnly = false,
    this.grid = false,
    this.canEdit = false,
    this.settings = const PriceSettings(),
  });

  final bool loading;
  final List<Item> items;
  final List<ItemCategory> categories;

  /// Items with a missing selling price, for the warning chip.
  final int missingCount;
  final String query;
  final String? categoryId;
  final bool missingOnly;
  final bool grid;

  /// Owner or editor: sees the missing-price chip.
  final bool canEdit;
  final PriceSettings settings;

  @override
  List<Object?> get props => [
    loading,
    items,
    categories,
    missingCount,
    query,
    categoryId,
    missingOnly,
    grid,
    canEdit,
    settings,
  ];
}

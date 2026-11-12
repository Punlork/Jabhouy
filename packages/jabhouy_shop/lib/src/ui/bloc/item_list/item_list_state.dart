part of 'item_list_cubit.dart';

/// How Home orders the Items when there is no search; a search ranks by match.
enum ItemSort { name, recent }

@CopyWith()
class ItemListState extends Equatable {
  const ItemListState({
    this.loading = true,
    this.items = const [],
    this.nicknameMatches = const {},
    this.recent = const [],
    this.categories = const [],
    this.missingCount = 0,
    this.query = '',
    this.categoryId,
    this.missingOnly = false,
    this.grid = false,
    this.sort = ItemSort.name,
    this.sortReversed = false,
    this.canEdit = false,
    this.settings = const PriceSettings(),
  });

  final bool loading;
  final List<Item> items;

  /// Item id → the nickname a search matched, for `ឈ្មោះផ្សេង៖`.
  final Map<String, String> nicknameMatches;

  /// Recently viewed Items, newest first.
  final List<Item> recent;
  final List<ItemCategory> categories;

  /// Items with a missing selling price, for the warning chip.
  final int missingCount;
  final String query;
  final String? categoryId;
  final bool missingOnly;
  final bool grid;
  final ItemSort sort;

  /// Flipped from the order [sort] starts in: Z–A, or oldest first.
  final bool sortReversed;

  /// Owner or editor: sees the missing-price chip.
  final bool canEdit;
  final PriceSettings settings;

  @override
  List<Object?> get props => [
    loading,
    items,
    nicknameMatches,
    recent,
    categories,
    missingCount,
    query,
    categoryId,
    missingOnly,
    grid,
    sort,
    sortReversed,
    canEdit,
    settings,
  ];
}

part of 'shop_bloc.dart';

sealed class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {
  const ShopInitial();
}

class ShopLoading extends ShopState {
  const ShopLoading();
}

class ShopLoaded extends ShopState {
  const ShopLoaded({
    required this.paginatedItems,
    this.searchQuery = '',
    this.categoryFilter,
    this.isFiltering,
  });

  final PaginatedResponse<ShopItemModel> paginatedItems;
  final String searchQuery;
  final CategoryItemModel? categoryFilter;
  final bool? isFiltering;

  List<ShopItemModel> get items => paginatedItems.items;

  List<CategoryItemModel> get itemCategories => paginatedItems.items
      .map((e) => e.category)
      .where((element) => element != null)
      .toSet()
      .toList()
      .cast<CategoryItemModel>();

  Pagination get pagination => paginatedItems.pagination;

  ShopLoaded copyWith({
    PaginatedResponse<ShopItemModel>? paginatedItems,
    String? searchQuery,
    CategoryItemModel? categoryFilter,
    String? buyerFilter,
    bool? isFiltering,
  }) {
    return ShopLoaded(
      paginatedItems: paginatedItems ?? this.paginatedItems,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        categoryFilter,
        paginatedItems,
        items.length,
        isFiltering,
        ...items,
      ];
}

class ShopError extends ShopState {
  const ShopError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

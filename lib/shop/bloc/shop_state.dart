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
    this.categoryFilter = 'All',
    this.buyerFilter = 'All',
  });

  final PaginatedResponse<ShopItemModel> paginatedItems;
  final String searchQuery;
  final String categoryFilter;
  final String buyerFilter;

  List<ShopItemModel> get items => paginatedItems.items;
  Pagination get pagination => paginatedItems.pagination;

  ShopLoaded copyWith({
    PaginatedResponse<ShopItemModel>? paginatedItems,
    String? searchQuery,
    String? categoryFilter,
    String? buyerFilter,
    bool? isMoreLoading,
  }) {
    return ShopLoaded(
      paginatedItems: paginatedItems ?? this.paginatedItems,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      buyerFilter: buyerFilter ?? this.buyerFilter,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        categoryFilter,
        buyerFilter,
        paginatedItems,
        items.length,
        ...items,
      ];
}

class ShopError extends ShopState {
  const ShopError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

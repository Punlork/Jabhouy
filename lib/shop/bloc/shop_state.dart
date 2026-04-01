part of 'shop_bloc.dart';

const _shopCategoryFilterUnset = Object();
const _shopSyncMessageUnset = Object();

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
    this.isOffline = false,
    this.syncMessage,
  });

  final PaginatedResponse<ShopItemModel> paginatedItems;
  final String searchQuery;
  final CategoryItemModel? categoryFilter;
  final bool? isFiltering;
  final bool isOffline;
  final String? syncMessage;

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
    Object? categoryFilter = _shopCategoryFilterUnset,
    bool? isFiltering,
    bool? isOffline,
    Object? syncMessage = _shopSyncMessageUnset,
  }) {
    return ShopLoaded(
      paginatedItems: paginatedItems ?? this.paginatedItems,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: identical(categoryFilter, _shopCategoryFilterUnset)
          ? this.categoryFilter
          : categoryFilter as CategoryItemModel?,
      isFiltering: isFiltering ?? this.isFiltering,
      isOffline: isOffline ?? this.isOffline,
      syncMessage: identical(syncMessage, _shopSyncMessageUnset)
          ? this.syncMessage
          : syncMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        categoryFilter,
        paginatedItems,
        items.length,
        isFiltering,
        isOffline,
        syncMessage,
        ...items,
      ];
}

class ShopError extends ShopState {
  const ShopError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

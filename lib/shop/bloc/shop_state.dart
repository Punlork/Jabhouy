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
    required this.items,
    this.searchQuery = '',
    this.categoryFilter = 'All',
    this.buyerFilter = 'All',
  });

  final List<ShopItemModel> items;
  final String searchQuery;
  final String categoryFilter;
  final String buyerFilter;

  ShopLoaded copyWith({
    List<ShopItemModel>? items,
    String? searchQuery,
    String? categoryFilter,
    String? buyerFilter,
  }) {
    return ShopLoaded(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      buyerFilter: buyerFilter ?? this.buyerFilter,
    );
  }

  @override
  List<Object?> get props => [...items, items.length, searchQuery, categoryFilter, buyerFilter];
}

class ShopError extends ShopState {
  const ShopError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

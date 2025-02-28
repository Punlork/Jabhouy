part of 'inventory_bloc.dart';

class InventoryState {
  InventoryState({
    required this.filteredItems,
    this.searchQuery = '',
    this.categoryFilter = 'All',
    this.buyerFilter = 'All',
  });
  
  final List<ShopItem> filteredItems;
  final String searchQuery;
  final String categoryFilter;
  final String buyerFilter;

  InventoryState copyWith({
    List<ShopItem>? filteredItems,
    String? searchQuery,
    String? categoryFilter,
    String? buyerFilter,
  }) {
    return InventoryState(
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      buyerFilter: buyerFilter ?? this.buyerFilter,
    );
  }
}

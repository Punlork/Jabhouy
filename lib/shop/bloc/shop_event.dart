part of 'shop_bloc.dart';

@immutable
abstract class ShopEvent {}

class ShopGetItemsEvent extends ShopEvent {
  ShopGetItemsEvent({
    this.searchQuery,
    this.categoryFilter,
    this.clearCategoryFilter = false,
    this.forceRefresh = false,
    this.limit,
    this.page,
  }) : isSearchChange = searchQuery != null;

  final String? searchQuery;
  final CategoryItemModel? categoryFilter;
  final bool clearCategoryFilter;

  final bool forceRefresh;
  final int? limit;
  final int? page;
  final bool isSearchChange;
}

class ShopCreateItemEvent extends ShopEvent {
  ShopCreateItemEvent({
    required this.body,
    this.onSuccess,
  });

  final ShopItemModel body;
  final VoidCallback? onSuccess;
}

class ShopEditItemEvent extends ShopEvent {
  ShopEditItemEvent({
    required this.body,
    this.onSuccess,
  });

  final ShopItemModel body;
  final VoidCallback? onSuccess;
}

class ShopDeleteItemEvent extends ShopEvent {
  ShopDeleteItemEvent({required this.body});

  final ShopItemModel body;
}

class _ShopInternalItemsUpdated extends ShopEvent {
  _ShopInternalItemsUpdated(this.items);
  final List<ShopItemModel> items;
}

class _ShopConnectivityChanged extends ShopEvent {
  _ShopConnectivityChanged({required this.isOnline});

  final bool isOnline;
}

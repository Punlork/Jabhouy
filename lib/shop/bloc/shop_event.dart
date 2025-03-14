part of 'shop_bloc.dart';

@immutable
abstract class ShopEvent {}

class ShopGetItemsEvent extends ShopEvent {
  ShopGetItemsEvent({
    this.searchQuery,
    this.categoryFilter,
    this.forceRefresh = false,
    this.pageSize,
    this.page,
  });

  final String? searchQuery;
  final CategoryItemModel? categoryFilter;

  final bool forceRefresh;
  final int? pageSize;
  final int? page;
}

class ShopCreateItemEvent extends ShopEvent {
  ShopCreateItemEvent({required this.body});

  final ShopItemModel body;
}

class ShopEditItemEvent extends ShopEvent {
  ShopEditItemEvent({required this.body});

  final ShopItemModel body;
}

class ShopDeleteItemEvent extends ShopEvent {
  ShopDeleteItemEvent({required this.body});

  final ShopItemModel body;
}

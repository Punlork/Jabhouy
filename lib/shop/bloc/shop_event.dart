part of 'shop_bloc.dart';

@immutable
abstract class ShopEvent {}

class ShopGetItemsEvent extends ShopEvent {
  ShopGetItemsEvent({
    this.searchQuery,
    this.categoryFilter,
    this.buyerFilter,
    this.forceRefresh = false,
  });

  final String? searchQuery; // Null means no change
  final String? categoryFilter; // Null means no change
  final String? buyerFilter; // Null means no change
  final bool forceRefresh; // Triggers a refresh if true
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

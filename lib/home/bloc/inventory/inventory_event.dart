part of 'inventory_bloc.dart';

@immutable
abstract class InventoryEvent {}

class SearchItemsEvent extends InventoryEvent {
  SearchItemsEvent(this.query);
  final String query;
}

class FilterItemsEvent extends InventoryEvent {
  FilterItemsEvent(this.categoryFilter, this.buyerFilter);
  final String categoryFilter;
  final String buyerFilter;
}

class RefreshItemsEvent extends InventoryEvent {}

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_app/home/widgets/widgets.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc(this.allItems) : super(InventoryState(filteredItems: allItems)) {
    on<SearchItemsEvent>(_onSearchItems);
    on<FilterItemsEvent>(_onFilterItems);
    on<RefreshItemsEvent>(_onRefreshItems);
  }
  final List<ShopItem> allItems;

  void _onSearchItems(SearchItemsEvent event, Emitter<InventoryState> emit) {
    emit(state.copyWith(searchQuery: event.query));
    _filterAndEmit(emit);
  }

  void _onFilterItems(FilterItemsEvent event, Emitter<InventoryState> emit) {
    emit(
      state.copyWith(
        categoryFilter: event.categoryFilter,
        buyerFilter: event.buyerFilter,
      ),
    );
    _filterAndEmit(emit);
  }

  Future<void> _onRefreshItems(RefreshItemsEvent event, Emitter<InventoryState> emit) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    emit(state.copyWith(filteredItems: allItems));
    _filterAndEmit(emit);
  }

  void _filterAndEmit(Emitter<InventoryState> emit) {
    final filtered = allItems.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          item.note.toLowerCase().contains(state.searchQuery.toLowerCase());
      final matchesCategory = state.categoryFilter == 'All' || item.category == state.categoryFilter;
      final matchesBuyer = state.buyerFilter == 'All' ||
          (state.buyerFilter == 'Customer Only' &&
              (item.customerPrice != item.defaultPrice ||
                  item.customerBatchPrice != item.defaultPrice * item.batchSize)) ||
          (state.buyerFilter == 'Seller Only' &&
              (item.sellerPrice != item.defaultPrice || item.sellerBatchPrice != item.defaultPrice * item.batchSize));
      return matchesSearch && matchesCategory && matchesBuyer;
    }).toList();

    emit(state.copyWith(filteredItems: filtered));
  }
}

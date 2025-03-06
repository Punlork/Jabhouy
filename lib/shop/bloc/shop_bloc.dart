import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

part 'shop_event.dart';
part 'shop_state.dart';

extension ShopStateExtension on ShopState {
  ShopLoaded? get asLoaded => this is ShopLoaded ? this as ShopLoaded : null;
}

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc(this._service) : super(const ShopInitial()) {
    on<ShopGetItemsEvent>(_onGetItems);
    on<ShopCreateItemEvent>(_onCreateItem);
    on<ShopDeleteItemEvent>(_onDeleteItem);
    on<ShopEditItemEvent>(_onEditItem);
  }

  final ShopService _service;

  Future<void> _onCreateItem(ShopCreateItemEvent event, Emitter<ShopState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.createShopItem(event.body);
      if (!response.success) return;

      showSuccessSnackBar(null, 'Created ${response.data?.name}');
      final updatedItems = List<ShopItemModel>.from(state.asLoaded?.items ?? [])..add(response.data!);
      emit(ShopLoaded(items: updatedItems));
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create item: $e');
    }
  }

  Future<void> _onEditItem(ShopEditItemEvent event, Emitter<ShopState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.updateShopItem(event.body);
      if (!response.success) return;

      showSuccessSnackBar(null, 'Updated ${response.data?.name}');

      final currentItems = state.asLoaded?.items ?? <ShopItemModel>[];

      final updatedItems = currentItems.map((item) {
        return item.id == event.body.id ? response.data! : item;
      }).toList();

      emit(ShopLoaded(items: updatedItems));
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update item: $e');
    }
  }

  Future<void> _onDeleteItem(ShopDeleteItemEvent event, Emitter<ShopState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.deleteShopItem(event.body);
      if (!response.success) return;

      showSuccessSnackBar(null, 'Deleted ${event.body.name}');
      final updatedItems = List<ShopItemModel>.from(state.asLoaded?.items ?? [])
        ..removeWhere(
          (item) => item.id == event.body.id,
        );
      emit(ShopLoaded(items: updatedItems));
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete item: $e');
    }
  }

  Future<void> _onGetItems(ShopGetItemsEvent event, Emitter<ShopState> emit) async {
    // Get current state if loaded, or use defaults
    final currentState = state is ShopLoaded ? state as ShopLoaded : null;

    // Determine new parameters, falling back to current state or defaults
    final newSearchQuery = event.searchQuery ?? currentState?.searchQuery ?? '';
    final newCategoryFilter = event.categoryFilter ?? currentState?.categoryFilter ?? 'All';
    final newBuyerFilter = event.buyerFilter ?? currentState?.buyerFilter ?? 'All';

    final shouldFetch = state is ShopInitial ||
        event.forceRefresh ||
        (state is ShopLoaded &&
            (newSearchQuery != currentState!.searchQuery ||
                newCategoryFilter != currentState.categoryFilter ||
                newBuyerFilter != currentState.buyerFilter));

    if (!shouldFetch) return;

    emit(const ShopLoading());
    try {
      final items = await _service.getShopItems(
          // query: newSearchQuery,
          // category: newCategoryFilter,
          // buyer: newBuyerFilter,
          );
      emit(
        ShopLoaded(
          items: items.data ?? [],
          searchQuery: newSearchQuery,
          categoryFilter: newCategoryFilter,
          buyerFilter: newBuyerFilter,
        ),
      );
    } catch (e) {
      emit(ShopError('Failed to load items: $e'));
    }
  }
}

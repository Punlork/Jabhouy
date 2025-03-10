import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

// ignore: depend_on_referenced_packages
import 'package:stream_transform/stream_transform.dart';

part 'shop_event.dart';
part 'shop_state.dart';

extension ShopStateExtension on ShopState {
  ShopLoaded? get asLoaded => this is ShopLoaded ? this as ShopLoaded : null;
}

const throttleDuration = Duration(milliseconds: 300);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc(this._service) : super(const ShopInitial()) {
    on<ShopGetItemsEvent>(
      _onGetItems,
      transformer: throttleDroppable(throttleDuration),
    );
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

      final updatedItems = [response.data!, ...?state.asLoaded?.items];

      emit(
        ShopLoaded(
          paginatedItems: PaginatedResponse<ShopItemModel>(
            items: updatedItems,
            pagination: state.asLoaded!.pagination,
          ),
          searchQuery: state.asLoaded?.searchQuery ?? '',
          categoryFilter: state.asLoaded?.categoryFilter,
          buyerFilter: state.asLoaded?.buyerFilter ?? 'All',
        ),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onEditItem(ShopEditItemEvent event, Emitter<ShopState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.updateShopItem(event.body);
      if (!response.success) return;

      showSuccessSnackBar(null, 'Updated: ${response.data?.name}');

      final currentItems = state.asLoaded?.items ?? <ShopItemModel>[];
      final updatedItems = currentItems.map((item) {
        return item.id == event.body.id ? response.data! : item;
      }).toList();

      emit(
        ShopLoaded(
          paginatedItems: PaginatedResponse<ShopItemModel>(
            items: updatedItems,
            pagination: state.asLoaded!.pagination,
          ),
          searchQuery: state.asLoaded?.searchQuery ?? '',
          categoryFilter: state.asLoaded?.categoryFilter,
          buyerFilter: state.asLoaded?.buyerFilter ?? 'All',
        ),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteItem(ShopDeleteItemEvent event, Emitter<ShopState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.deleteShopItem(event.body);
      if (!response.success) return;

      showSuccessSnackBar(null, 'Deleted ${event.body.name}');

      final updatedItems = List<ShopItemModel>.from(state.asLoaded?.items ?? [])
        ..removeWhere((item) => item.id == event.body.id);

      emit(
        ShopLoaded(
          paginatedItems: PaginatedResponse<ShopItemModel>(
            items: updatedItems,
            pagination: state.asLoaded?.pagination != null
                ? Pagination(
                    total: updatedItems.length,
                    page: state.asLoaded!.pagination.page,
                    pageSize: state.asLoaded!.pagination.pageSize,
                    totalPage: (updatedItems.length / state.asLoaded!.pagination.pageSize).ceil(),
                  )
                : Pagination(
                    total: updatedItems.length,
                    totalPage: 1,
                  ),
          ),
          searchQuery: state.asLoaded?.searchQuery ?? '',
          categoryFilter: state.asLoaded?.categoryFilter,
          buyerFilter: state.asLoaded?.buyerFilter ?? 'All',
        ),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onGetItems(ShopGetItemsEvent event, Emitter<ShopState> emit) async {
    final currentState = state.asLoaded;

    final newSearchQuery = event.searchQuery ?? currentState?.searchQuery ?? '';
    final newCategoryFilter = event.categoryFilter ?? currentState?.categoryFilter;
    final newBuyerFilter = event.buyerFilter ?? currentState?.buyerFilter ?? 'All';
    final newPage = event.page ?? (currentState?.pagination.page ?? 1);
    final newPageSize = event.pageSize ?? (currentState?.pagination.pageSize ?? 10);

    final isFilterChange = newSearchQuery != currentState?.searchQuery ||
        newCategoryFilter != currentState?.categoryFilter ||
        newBuyerFilter != currentState?.buyerFilter;

    final effectivePage = isFilterChange ? 1 : newPage;

    final showFilterLoading = effectivePage == 1 && isFilterChange;

    if (state is ShopInitial || (event.forceRefresh && effectivePage == 1) || showFilterLoading) {
      emit(const ShopLoading());
    }

    try {
      final response = await _service.getShopItems(
        page: effectivePage,
        pageSize: newPageSize,
        searchQuery: newSearchQuery,
        categoryFilter: newCategoryFilter?.name ?? '',
        buyerFilter: newBuyerFilter,
      );

      if (response.success && response.data != null) {
        final paginatedItems = response.data!.items;
        final pagination = response.data!.pagination;

        var allItems = <ShopItemModel>[];

        if (event.forceRefresh || isFilterChange || effectivePage == 1) {
          allItems = paginatedItems;
        } else {
          allItems = [...currentState!.items, ...paginatedItems];
        }

        emit(
          ShopLoaded(
            paginatedItems: PaginatedResponse(
              items: allItems,
              pagination: pagination,
            ),
            searchQuery: newSearchQuery,
            categoryFilter: newCategoryFilter,
            buyerFilter: newBuyerFilter,
          ),
        );
      }
    } catch (e) {
      emit(ShopError('Failed to load items: $e'));
    }
  }
}

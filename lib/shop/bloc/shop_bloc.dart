import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';
import 'package:stream_transform/stream_transform.dart';

part 'shop_event.dart';
part 'shop_state.dart';

extension ShopStateExtension on ShopState {
  ShopLoaded? get asLoaded => this is ShopLoaded ? this as ShopLoaded : null;
}

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc(this._service, this.upload) : super(const ShopInitial()) {
    _filtersController = StreamController<_ShopFilters>.broadcast(sync: true)..add(const _ShopFilters());

    _itemsSubscription = _filtersController.stream
        .switchMap(
      (filters) => _service.watchShopItems(
        searchQuery: filters.searchQuery,
        categoryFilter: filters.categoryFilter,
      ),
    )
        .listen((items) {
      add(
        _ShopInternalItemsUpdated(items),
      );
    });

    on<_ShopInternalItemsUpdated>((event, emit) {
      final currentState = state.asLoaded;
      emit(
        ShopLoaded(
          paginatedItems: PaginatedResponse<ShopItemModel>(
            items: event.items,
            pagination: currentState?.pagination ?? Pagination(total: event.items.length, totalPage: 1),
          ),
          searchQuery: currentState?.searchQuery ?? '',
          categoryFilter: currentState?.categoryFilter,
        ),
      );
    });

    on<ShopGetItemsEvent>(
      _onGetItems,
      transformer: (events, mapper) {
        final searchEvents = events.where((e) => e.isSearch).debounce(throttleDuration);
        final scrollEvents = events.where((e) => !e.isSearch).throttle(throttleDuration);
        return droppable<ShopGetItemsEvent>().call(
          searchEvents.merge(scrollEvents),
          mapper,
        );
      },
    );
    on<ShopCreateItemEvent>(_onCreateItem);
    on<ShopDeleteItemEvent>(_onDeleteItem);
    on<ShopEditItemEvent>(_onEditItem);
  }

  static const throttleDuration = Duration(milliseconds: 300);

  final ShopService _service;
  final UploadBloc upload;
  late StreamSubscription<List<ShopItemModel>> _itemsSubscription;
  late StreamController<_ShopFilters> _filtersController;

  @override
  Future<void> close() {
    _itemsSubscription.cancel();
    _filtersController.close();
    return super.close();
  }

  Future<void> _onCreateItem(ShopCreateItemEvent event, Emitter<ShopState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.createShopItem(event.body);
      if (!response.success) return;
      showSuccessSnackBar(null, 'Created ${response.data?.name}');
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
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onGetItems(ShopGetItemsEvent event, Emitter<ShopState> emit) async {
    final currentState = state.asLoaded;

    final newSearchQuery = event.searchQuery ?? currentState?.searchQuery ?? '';
    final newCategoryFilter = event.categoryFilter;
    final newPage = event.page ?? (currentState?.pagination.page ?? 1);
    final newPageSize = event.limit ?? (currentState?.pagination.limit ?? 100);

    final isFilterChange = newSearchQuery != currentState?.searchQuery;
    final isCategoryChange = newCategoryFilter != currentState?.categoryFilter;

    if (isFilterChange || isCategoryChange) {
      _filtersController.add(
        _ShopFilters(
          searchQuery: newSearchQuery,
          categoryFilter: newCategoryFilter,
        ),
      );
    }

    final effectivePage = isFilterChange || isCategoryChange ? 1 : newPage;
    final showFilterLoading = effectivePage == 1 && (isFilterChange || isCategoryChange);

    if (isCategoryChange || event.forceRefresh || isFilterChange) {
      if (currentState != null) {
        emit(
          currentState.copyWith(
            isFiltering: true,
            categoryFilter: newCategoryFilter,
            searchQuery: newSearchQuery,
          ),
        );
      }
    } else if (state is ShopInitial || effectivePage == 1 || showFilterLoading) {
      emit(const ShopLoading());
    }

    try {
      // Still fetch from API to update local DB
      await _service.getShopItems(
        page: effectivePage,
        limit: newPageSize,
        searchQuery: newSearchQuery,
        categoryFilter: newCategoryFilter?.id.toString() ?? '',
      );
      // We don't need to emit ShopLoaded here because the stream subscription will do it
    } catch (e) {
      if (state is! ShopLoaded) {
        emit(ShopError('Failed to load items: $e'));
      }
    }
  }
}

class _ShopFilters {
  const _ShopFilters({
    this.searchQuery = '',
    this.categoryFilter,
  });

  final String searchQuery;
  final CategoryItemModel? categoryFilter;
}

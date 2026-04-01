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
  ShopBloc(this._service, this.upload, this._connectivityService) : super(const ShopInitial()) {
    _filtersController = StreamController<_ShopFilters>.broadcast(sync: true)
      ..add(
        const _ShopFilters(),
      );

    _itemsSubscription = _filtersController.stream
        .switchMap(
          (filters) => _service.watchShopItems(
            searchQuery: filters.searchQuery,
            categoryFilter: filters.categoryFilter,
          ),
        )
        .listen(
          (items) => add(_ShopInternalItemsUpdated(items)),
        );

    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isOnline) => add(_ShopConnectivityChanged(isOnline: isOnline)),
    );

    on<_ShopInternalItemsUpdated>((event, emit) {
      final currentState = state.asLoaded;
      emit(
        ShopLoaded(
          paginatedItems: PaginatedResponse<ShopItemModel>(
            items: event.items,
            pagination: currentState?.pagination ??
                Pagination(
                  total: event.items.length,
                  totalPage: 1,
                ),
          ),
          searchQuery: currentState?.searchQuery ?? '',
          categoryFilter: currentState?.categoryFilter,
          isFiltering: false,
          isOffline: currentState?.isOffline ?? false,
          syncMessage: currentState?.syncMessage,
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
    on<_ShopConnectivityChanged>(_onConnectivityChanged);
  }

  static const throttleDuration = Duration(milliseconds: 300);

  final ShopService _service;
  final UploadBloc upload;
  final ConnectivityService _connectivityService;
  late StreamSubscription<List<ShopItemModel>> _itemsSubscription;
  late StreamSubscription<bool> _connectivitySubscription;
  late StreamController<_ShopFilters> _filtersController;

  @override
  Future<void> close() {
    _itemsSubscription.cancel();
    _connectivitySubscription.cancel();
    _filtersController.close();
    return super.close();
  }

  Future<void> _onCreateItem(
    ShopCreateItemEvent event,
    Emitter<ShopState> emit,
  ) async {
    LoadingOverlay.show();
    try {
      final response = await _service.createShopItem(event.body);
      if (!response.success) return;
      showSuccessSnackBar(
        null,
        response.message ?? 'Created ${response.data?.name}',
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onEditItem(
    ShopEditItemEvent event,
    Emitter<ShopState> emit,
  ) async {
    LoadingOverlay.show();
    try {
      final response = await _service.updateShopItem(event.body);
      if (!response.success) return;
      showSuccessSnackBar(
        null,
        response.message ?? 'Updated: ${response.data?.name}',
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteItem(
    ShopDeleteItemEvent event,
    Emitter<ShopState> emit,
  ) async {
    LoadingOverlay.show();
    try {
      final response = await _service.deleteShopItem(event.body);
      if (!response.success) return;
      showSuccessSnackBar(
        null,
        response.message ?? 'Deleted ${event.body.name}',
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onGetItems(
    ShopGetItemsEvent event,
    Emitter<ShopState> emit,
  ) async {
    final currentState = state.asLoaded;

    final newSearchQuery = event.searchQuery ?? currentState?.searchQuery ?? '';
    final newCategoryFilter = event.categoryFilter;
    final newPage = event.page ?? (currentState?.pagination.page ?? 1);
    final newPageSize = event.limit ?? (currentState?.pagination.limit ?? 100);

    final isFilterChange = newSearchQuery != currentState?.searchQuery;
    final isCategoryChange = newCategoryFilter != currentState?.categoryFilter;
    final effectivePage = isFilterChange || isCategoryChange ? 1 : newPage;

    final hasCachedItems = await _service.hasCachedShopItems(
      searchQuery: newSearchQuery,
      categoryFilter: newCategoryFilter,
    );

    final isOnline = await _connectivityService.isOnline;

    if (isFilterChange || isCategoryChange) {
      _filtersController.add(
        _ShopFilters(
          searchQuery: newSearchQuery,
          categoryFilter: newCategoryFilter,
        ),
      );
    }

    final showFilterLoading = !hasCachedItems && effectivePage == 1 && (isFilterChange || isCategoryChange);

    if (isCategoryChange || event.forceRefresh || isFilterChange) {
      if (currentState != null) {
        emit(
          currentState.copyWith(
            isFiltering: showFilterLoading,
            categoryFilter: newCategoryFilter,
            searchQuery: newSearchQuery,
            isOffline: !isOnline,
            syncMessage: !isOnline ? _offlineMessage(hasCachedItems) : null,
          ),
        );
      } else if (!hasCachedItems) {
        emit(const ShopLoading());
      }
    } else if ((state is ShopInitial || effectivePage == 1) && !hasCachedItems) {
      emit(const ShopLoading());
    }

    if (!isOnline) {
      if (currentState != null) {
        emit(
          currentState.copyWith(
            categoryFilter: newCategoryFilter,
            searchQuery: newSearchQuery,
            isFiltering: false,
            isOffline: true,
            syncMessage: _offlineMessage(hasCachedItems),
          ),
        );
      } else if (!hasCachedItems) {
        emit(
          const ShopError(
            'You are offline and there is no cached shop data yet.',
          ),
        );
      }
      return;
    }

    final response = await _service.getShopItems(
      page: effectivePage,
      limit: newPageSize,
      searchQuery: newSearchQuery,
      categoryFilter: newCategoryFilter?.id.toString() ?? '',
    );

    if (response.success && response.data != null) {
      final loadedState = state.asLoaded;
      if (loadedState != null) {
        emit(
          loadedState.copyWith(
            paginatedItems: loadedState.paginatedItems.copyWith(
              pagination: response.data!.pagination,
            ),
            categoryFilter: newCategoryFilter,
            searchQuery: newSearchQuery,
            isFiltering: false,
            isOffline: false,
            syncMessage: null,
          ),
        );
      } else {
        emit(
          ShopLoaded(
            paginatedItems: response.data!,
            searchQuery: newSearchQuery,
            categoryFilter: newCategoryFilter,
          ),
        );
      }
      return;
    }

    if (state is ShopLoaded || hasCachedItems) {
      final loadedState = state.asLoaded;
      if (loadedState != null) {
        emit(
          loadedState.copyWith(
            isFiltering: false,
            isOffline: false,
            syncMessage: 'Failed to refresh. Showing cached data.',
          ),
        );
      }
      return;
    }

    emit(ShopError(response.message ?? 'Failed to load items.'));
  }

  Future<void> _onConnectivityChanged(
    _ShopConnectivityChanged event,
    Emitter<ShopState> emit,
  ) async {
    final currentState = state.asLoaded;

    if (!event.isOnline) {
      if (currentState != null) {
        emit(
          currentState.copyWith(
            isOffline: true,
            syncMessage: _offlineMessage(currentState.items.isNotEmpty),
          ),
        );
      }
      return;
    }

    if (currentState != null) {
      emit(
        currentState.copyWith(
          isOffline: false,
          syncMessage: 'Back online. Syncing changes...',
        ),
      );
    }

    await _service.syncPendingChanges();

    final response = await _service.getShopItems(
      page: currentState?.pagination.page ?? 1,
      limit: currentState?.pagination.limit ?? 100,
      searchQuery: currentState?.searchQuery ?? '',
      categoryFilter: currentState?.categoryFilter?.id.toString() ?? '',
    );

    final latestState = state.asLoaded;
    if (latestState == null) {
      return;
    }

    if (response.success && response.data != null) {
      emit(
        latestState.copyWith(
          paginatedItems: latestState.paginatedItems.copyWith(
            pagination: response.data!.pagination,
          ),
          isFiltering: false,
          isOffline: false,
          syncMessage: null,
        ),
      );
      return;
    }

    emit(
      latestState.copyWith(
        isFiltering: false,
        isOffline: false,
        syncMessage: response.message == null ? null : 'Back online, but refresh failed.',
      ),
    );
  }

  String _offlineMessage(bool hasCachedItems) {
    if (hasCachedItems) {
      return 'Offline - showing cached data.';
    }

    return 'Offline - connect once to cache shop data.';
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

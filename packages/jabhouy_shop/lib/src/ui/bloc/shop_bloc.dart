import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:stream_transform/stream_transform.dart';

part 'shop_event.dart';
part 'shop_state.dart';
part 'shop_bloc.g.dart';

extension ShopStateExtension on ShopState {
  ShopLoaded? get asLoaded => this is ShopLoaded ? this as ShopLoaded : null;
}

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc(
    this._repository,
    this.upload,
    this._connectivityService, {
    FeatureFlags flags = const FixedFeatureFlags({}),
  })  : _inBackground = flags.isEnabled(Feature.backgroundSync),
        super(const ShopInitial()) {
    _filtersController = StreamController<_ShopFilters>.broadcast(sync: true)
      ..add(
        const _ShopFilters(),
      );

    _itemsSubscription = _filtersController.stream
        .switchMap(
      (filters) => _repository.watchItems(
        searchQuery: filters.searchQuery,
        categoryFilter: filters.categoryFilter,
      ),
    )
        .listen((items) {
      if (!isClosed) {
        add(_ShopInternalItemsUpdated(items));
      }
    });

    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isOnline) {
        if (!isClosed) {
          add(_ShopConnectivityChanged(isOnline: isOnline));
        }
      },
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
        final searchEvents = restartable<ShopGetItemsEvent>().call(
          events.where((e) => e.isSearchChange).debounce(throttleDuration),
          mapper,
        );
        final immediateEvents = restartable<ShopGetItemsEvent>().call(
          events.where(
            (e) =>
                !e.isSearchChange &&
                (e.isCategoryChangeRequest || e.forceRefresh),
          ),
          mapper,
        );
        final scrollEvents = droppable<ShopGetItemsEvent>().call(
          events
              .where(
                (e) =>
                    !e.isSearchChange &&
                    !e.isCategoryChangeRequest &&
                    !e.forceRefresh,
              )
              .throttle(throttleDuration),
          mapper,
        );
        return searchEvents.merge(immediateEvents).merge(scrollEvents);
      },
    );
    on<ShopCreateItemEvent>(_onCreateItem);
    on<ShopCreateItemsEvent>(_onCreateItems);
    on<ShopDeleteItemEvent>(_onDeleteItem);
    on<ShopEditItemEvent>(_onEditItem);
    on<_ShopConnectivityChanged>(_onConnectivityChanged);
  }

  static const throttleDuration = Duration(milliseconds: 300);

  /// Saves return at once and sync in the background: no overlay, and
  /// no claim about the server in the message.
  final bool _inBackground;
  final ShopRepository _repository;
  final UploadBloc upload;
  final ConnectivityService _connectivityService;
  late StreamSubscription<List<ShopItemModel>> _itemsSubscription;
  late StreamSubscription<bool> _connectivitySubscription;
  late StreamController<_ShopFilters> _filtersController;

  /// Pull-to-refresh. With background sync it returns the pull itself, so
  /// the spinner stays until the download ends and a second swipe cannot
  /// start while one runs; the engine folds any that do into one.
  Future<void> refresh() async {
    if (_inBackground) return _repository.pullLatest();
    final current = state.asLoaded;
    add(
      ShopGetItemsEvent(
        forceRefresh: true,
        page: 1,
        limit: current?.pagination.limit ?? 100,
        searchQuery: current?.searchQuery,
        categoryFilter: current?.categoryFilter,
      ),
    );
  }

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
    if (!_inBackground) LoadingOverlay.show();
    try {
      (await _repository.createItem(event.body)).fold(
        ok: (item) {
          showSuccessSnackBar(
            null,
            syncFeedback(item.syncStatus, done: 'Created ${item.name}', inBackground: _inBackground),
          );
          event.onSuccess?.call();
        },
        err: (e) =>
            showErrorSnackBar(null, 'Failed to create item: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create item: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onEditItem(
    ShopEditItemEvent event,
    Emitter<ShopState> emit,
  ) async {
    if (!_inBackground) LoadingOverlay.show();
    try {
      (await _repository.updateItem(event.body)).fold(
        ok: (item) {
          showSuccessSnackBar(
            null,
            syncFeedback(item.syncStatus, done: 'Updated: ${item.name}', inBackground: _inBackground),
          );
          event.onSuccess?.call();
        },
        err: (e) =>
            showErrorSnackBar(null, 'Failed to update item: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update item: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onCreateItems(
    ShopCreateItemsEvent event,
    Emitter<ShopState> emit,
  ) async {
    if (event.items.isEmpty) {
      return;
    }

    if (!_inBackground) LoadingOverlay.show();
    try {
      for (final item in event.items) {
        final result = await _repository.createItem(item);
        if (result case Err(:final error)) {
          showErrorSnackBar(
            null,
            'Failed to create ${item.name}: ${error.message}',
          );
          return;
        }
      }

      showSuccessSnackBar(
        null,
        event.items.length == 1
            ? 'Created ${event.items.first.name}'
            : 'Created ${event.items.length} items',
      );
      event.onSuccess?.call();
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create items: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteItem(
    ShopDeleteItemEvent event,
    Emitter<ShopState> emit,
  ) async {
    if (!_inBackground) LoadingOverlay.show();
    try {
      (await _repository.deleteItem(event.body)).fold(
        ok: (_) => showSuccessSnackBar(null, 'Deleted ${event.body.name}'),
        err: (e) =>
            showErrorSnackBar(null, 'Failed to delete item: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete item: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onGetItems(
    ShopGetItemsEvent event,
    Emitter<ShopState> emit,
  ) async {
    if (isClosed) {
      return;
    }

    final currentState = state.asLoaded;

    final newSearchQuery = event.searchQuery ?? currentState?.searchQuery ?? '';
    final newCategoryFilter = event.clearCategoryFilter
        ? null
        : event.categoryFilter ?? currentState?.categoryFilter;
    final newPage = event.page ?? (currentState?.pagination.page ?? 1);
    final newPageSize = event.limit ?? (currentState?.pagination.limit ?? 100);

    final isFilterChange = newSearchQuery != currentState?.searchQuery;
    final isCategoryChange = newCategoryFilter != currentState?.categoryFilter;
    final effectivePage = isFilterChange || isCategoryChange ? 1 : newPage;
    final shouldUpdateFilters = isFilterChange || isCategoryChange;

    if (shouldUpdateFilters && !_filtersController.isClosed) {
      _filtersController.add(
        _ShopFilters(
          searchQuery: newSearchQuery,
          categoryFilter: newCategoryFilter,
        ),
      );
    }

    if (currentState != null && (shouldUpdateFilters || event.forceRefresh)) {
      emit(
        currentState.copyWith(
          categoryFilter: newCategoryFilter,
          searchQuery: newSearchQuery,
          isFiltering: false,
        ),
      );
    }

    if (_inBackground) {
      // The list is the Drift watch, re-pointed above; the engine keeps
      // its rows fresh. Only pull-to-refresh asks for a pull now.
      if (event.forceRefresh) await _repository.pullLatest();
      return;
    }

    final hasCachedItems = await _repository.hasCachedItems(
      searchQuery: newSearchQuery,
      categoryFilter: newCategoryFilter,
    );

    final isOnline = await _connectivityService.isOnline;

    if (isClosed) {
      return;
    }

    final showFilterLoading = event.forceRefresh &&
        !hasCachedItems &&
        effectivePage == 1 &&
        currentState == null;

    if (isCategoryChange || event.forceRefresh || isFilterChange) {
      if (currentState != null) {
        emit(
          state.asLoaded!.copyWith(
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
    } else if ((state is ShopInitial || effectivePage == 1) &&
        !hasCachedItems) {
      emit(const ShopLoading());
    }

    if (!isOnline) {
      if (currentState != null) {
        emit(
          state.asLoaded!.copyWith(
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

    final result = await _repository.refreshItems(
      page: effectivePage,
      limit: newPageSize,
      searchQuery: newSearchQuery,
      categoryFilter: newCategoryFilter?.id.toString() ?? '',
    );

    if (isClosed) {
      return;
    }

    if (result case Ok(:final value)) {
      final loadedState = state.asLoaded;
      if (loadedState != null) {
        emit(
          loadedState.copyWith(
            paginatedItems: loadedState.paginatedItems.copyWith(
              pagination: value.pagination,
            ),
            categoryFilter: newCategoryFilter,
            searchQuery: newSearchQuery,
            isFiltering: false,
            isOffline: false,
            // ignore: avoid_redundant_argument_values -- null clears the banner; omitting it would keep the old one.
            syncMessage: null,
          ),
        );
      } else {
        emit(
          ShopLoaded(
            paginatedItems: value,
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

    emit(
      ShopError(result.errorOrNull?.message ?? 'Failed to load items.'),
    );
  }

  Future<void> _onConnectivityChanged(
    _ShopConnectivityChanged event,
    Emitter<ShopState> emit,
  ) async {
    if (isClosed) {
      return;
    }

    final currentState = state.asLoaded;

    if (!event.isOnline) {
      if (currentState != null) {
        emit(
          currentState.copyWith(
            isOffline: true,
            // The sync indicator says how many changes wait, in place of this.
            syncMessage: _inBackground ? null : _offlineMessage(currentState.items.isNotEmpty),
          ),
        );
      }
      return;
    }

    if (_inBackground) {
      // SyncCoordinator pushes and pulls on reconnect.
      if (currentState != null) {
        // ignore: avoid_redundant_argument_values -- null clears the banner; omitting it would keep the old one.
        emit(currentState.copyWith(isOffline: false, syncMessage: null));
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

    await _repository.syncPendingChanges();

    final result = await _repository.refreshItems(
      page: currentState?.pagination.page ?? 1,
      limit: currentState?.pagination.limit ?? 100,
      searchQuery: currentState?.searchQuery ?? '',
      categoryFilter: currentState?.categoryFilter?.id.toString() ?? '',
    );

    if (isClosed) {
      return;
    }

    final latestState = state.asLoaded;
    if (latestState == null) {
      return;
    }

    if (result case Ok(:final value)) {
      emit(
        latestState.copyWith(
          paginatedItems: latestState.paginatedItems.copyWith(
            pagination: value.pagination,
          ),
          isFiltering: false,
          isOffline: false,
          // ignore: avoid_redundant_argument_values -- null clears the banner; omitting it would keep the old one.
          syncMessage: null,
        ),
      );
      return;
    }

    emit(
      latestState.copyWith(
        isFiltering: false,
        isOffline: false,
        syncMessage: 'Back online, but refresh failed.',
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

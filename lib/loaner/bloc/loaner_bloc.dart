// ignore_for_file: inference_failure_on_instance_creation

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:stream_transform/stream_transform.dart';

part 'loaner_event.dart';
part 'loaner_state.dart';

extension ShopStateExtension on LoanerState {
  LoanerLoaded? get asLoaded =>
      this is LoanerLoaded ? this as LoanerLoaded : null;
}

class LoanerBloc extends Bloc<LoanerEvent, LoanerState> {
  LoanerBloc(this._service, this._connectivityService)
      : super(LoanerInitial()) {
    _filtersController = StreamController<_LoanerFilters>.broadcast(sync: true)
      ..add(const _LoanerFilters());

    _loanerSubscription = _filtersController.stream
        .switchMap(
      (filters) => _service.watchLoaners(
        searchQuery: filters.searchQuery,
        customerFilter: filters.loanerFilter,
        fromDate: filters.fromDate,
        toDate: filters.toDate,
      ),
    )
        .listen((items) {
      add(_LoanerUpdatedFromLocal(items));
    });

    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isOnline) => add(_LoanerConnectivityChanged(isOnline: isOnline)),
    );

    on<_LoanerUpdatedFromLocal>((event, emit) {
      final currentState = state.asLoaded;
      emit(
        LoanerLoaded(
          PaginatedResponse(
            items: event.items,
            pagination: currentState?.pagination ??
                Pagination(total: event.items.length, totalPage: 1),
          ),
          searchQuery: currentState?.searchQuery ?? '',
          fromDate: currentState?.fromDate,
          toDate: currentState?.toDate,
          loanerFilter: currentState?.loanerFilter,
          isOffline: currentState?.isOffline ?? false,
          syncMessage: currentState?.syncMessage,
        ),
      );
    });

    on<LoadLoaners>(
      _onLoadLoaners,
      transformer: (events, mapper) {
        final searchEvents =
            events.where((e) => e.isSearch).debounce(throttleDuration);
        final scrollEvents =
            events.where((e) => !e.isSearch).throttle(throttleDuration);
        return droppable<LoadLoaners>().call(
          searchEvents.merge(scrollEvents),
          mapper,
        );
      },
    );
    on<AddLoaner>(_onAddLoaner);
    on<UpdateLoaner>(_onUpdateLoaner);
    on<DeleteLoaner>(_onDeleteLoaner);
    on<_LoanerConnectivityChanged>(_onConnectivityChanged);
  }
  static const throttleDuration = Duration(milliseconds: 300);

  final LoanerService _service;
  final ConnectivityService _connectivityService;
  late StreamSubscription<List<LoanerModel>> _loanerSubscription;
  late StreamSubscription<bool> _connectivitySubscription;
  late StreamController<_LoanerFilters> _filtersController;

  @override
  Future<void> close() {
    _loanerSubscription.cancel();
    _connectivitySubscription.cancel();
    _filtersController.close();
    return super.close();
  }

  Future<void> _onLoadLoaners(
    LoadLoaners event,
    Emitter<LoanerState> emit,
  ) async {
    final currentState = state.asLoaded;

    final newPage = event.page ?? (currentState?.pagination.page ?? 1);
    final newLimit = event.limit ?? (currentState?.pagination.limit ?? 10);
    final newSearchQuery = event.searchQuery ?? currentState?.searchQuery ?? '';
    final newFromDate = event.fromDate;
    final newToDate = event.toDate;
    final newLoanerFilter = event.loanerFilter;

    final isFilterChange = newSearchQuery != currentState?.searchQuery ||
        newFromDate != currentState?.fromDate ||
        newToDate != currentState?.toDate ||
        newLoanerFilter != currentState?.loanerFilter;

    final effectivePage = isFilterChange ? 1 : newPage;
    final hasCachedItems = await _service.hasCachedLoaners(
      searchQuery: newSearchQuery,
      customerFilter: newLoanerFilter,
      fromDate: newFromDate,
      toDate: newToDate,
    );
    final isOnline = await _connectivityService.isOnline;

    if (isFilterChange) {
      _filtersController.add(
        _LoanerFilters(
          searchQuery: newSearchQuery,
          fromDate: newFromDate,
          toDate: newToDate,
          loanerFilter: newLoanerFilter,
        ),
      );
    }

    if ((state is LoanerInitial || effectivePage == 1 || event.forceRefresh) &&
        !hasCachedItems) {
      emit(const LoanerLoading());
    }

    if (!isOnline) {
      if (currentState != null) {
        emit(
          currentState.copyWith(
            searchQuery: newSearchQuery,
            fromDate: newFromDate,
            toDate: newToDate,
            loanerFilter: newLoanerFilter,
            isOffline: true,
            syncMessage: _offlineMessage(hasCachedItems),
          ),
        );
      } else if (!hasCachedItems) {
        emit(
          const LoanerError(
            'You are offline and there is no cached loan data yet.',
          ),
        );
      }
      return;
    }

    final response = await _service.getLoaners(
      limit: newLimit,
      page: effectivePage,
      searchQuery: newSearchQuery,
      customer: newLoanerFilter?.id.toString(),
      fromDate: newFromDate,
      toDate: newToDate,
    );

    if (response.success && response.data != null) {
      final latestState = state.asLoaded;
      if (latestState != null) {
        emit(
          latestState.copyWith(
            response: latestState.response.copyWith(
              pagination: response.data!.pagination,
            ),
            searchQuery: newSearchQuery,
            fromDate: newFromDate,
            toDate: newToDate,
            loanerFilter: newLoanerFilter,
            isOffline: false,
            syncMessage: null,
          ),
        );
      } else {
        emit(
          LoanerLoaded(
            response.data!,
            searchQuery: newSearchQuery,
            fromDate: newFromDate,
            toDate: newToDate,
            loanerFilter: newLoanerFilter,
          ),
        );
      }
      return;
    }

    if (state is LoanerLoaded || hasCachedItems) {
      final latestState = state.asLoaded;
      if (latestState != null) {
        emit(
          latestState.copyWith(
            searchQuery: newSearchQuery,
            fromDate: newFromDate,
            toDate: newToDate,
            loanerFilter: newLoanerFilter,
            isOffline: false,
            syncMessage: 'Failed to refresh. Showing cached loaners.',
          ),
        );
      }
      return;
    }

    emit(LoanerError(response.message ?? 'Failed to load items.'));
  }

  Future<void> _onAddLoaner(AddLoaner event, Emitter<LoanerState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.createLoaner(event.loaner);
      if (!response.success) return;
      showSuccessSnackBar(
        null,
        response.message ?? 'Created ${event.loaner.customer?.name}',
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create loaner: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onUpdateLoaner(
    UpdateLoaner event,
    Emitter<LoanerState> emit,
  ) async {
    LoadingOverlay.show();
    try {
      final response = await _service.updateLoaner(event.loaner);
      if (!response.success) return;
      showSuccessSnackBar(
        null,
        response.message ?? 'Updated ${event.loaner.customer?.name}',
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update loaner: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteLoaner(
    DeleteLoaner event,
    Emitter<LoanerState> emit,
  ) async {
    LoadingOverlay.show();
    try {
      final response = await _service.deleteLoaner(event.body);
      if (!response.success) return;
      showSuccessSnackBar(
        null,
        response.message ?? 'Deleted ${event.body.customer?.name}',
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete loaner: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onConnectivityChanged(
    _LoanerConnectivityChanged event,
    Emitter<LoanerState> emit,
  ) async {
    final currentState = state.asLoaded;
    if (currentState == null) {
      return;
    }

    if (!event.isOnline) {
      emit(
        currentState.copyWith(
          isOffline: true,
          syncMessage: _offlineMessage(currentState.items.isNotEmpty),
        ),
      );
      return;
    }

    emit(
      currentState.copyWith(
        isOffline: false,
        syncMessage: 'Back online. Syncing loaners...',
      ),
    );

    await _service.syncPendingChanges();
    final response = await _service.getLoaners(
      limit: currentState.pagination.limit,
      page: currentState.pagination.page,
      searchQuery: currentState.searchQuery,
      customer: currentState.loanerFilter?.id.toString(),
      fromDate: currentState.fromDate,
      toDate: currentState.toDate,
    );
    final latestState = state.asLoaded;
    if (latestState == null) {
      return;
    }

    if (response.success && response.data != null) {
      emit(
        latestState.copyWith(
          response: latestState.response.copyWith(
            pagination: response.data!.pagination,
          ),
          isOffline: false,
          syncMessage: null,
        ),
      );
      return;
    }

    emit(
      latestState.copyWith(
        isOffline: false,
        syncMessage: 'Back online, but loaner refresh failed.',
      ),
    );
  }

  String _offlineMessage(bool hasCachedItems) {
    if (hasCachedItems) {
      return 'Offline - showing cached loaners.';
    }
    return 'Offline - connect once to cache loaners.';
  }
}

class _LoanerUpdatedFromLocal extends LoanerEvent {
  const _LoanerUpdatedFromLocal(this.items);
  final List<LoanerModel> items;
}

class _LoanerFilters {
  const _LoanerFilters({
    this.searchQuery = '',
    this.fromDate,
    this.toDate,
    this.loanerFilter,
  });

  final String searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final CustomerModel? loanerFilter;
}

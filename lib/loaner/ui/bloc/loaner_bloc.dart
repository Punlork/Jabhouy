// ignore_for_file: inference_failure_on_instance_creation

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:stream_transform/stream_transform.dart';

part 'loaner_event.dart';
part 'loaner_state.dart';
part 'loaner_bloc.g.dart';

extension ShopStateExtension on LoanerState {
  LoanerLoaded? get asLoaded =>
      this is LoanerLoaded ? this as LoanerLoaded : null;
}

class LoanerBloc extends Bloc<LoanerEvent, LoanerState> {
  LoanerBloc(
    this._repository,
    this._refreshLoaners,
    this._connectivityService, {
    FeatureFlags flags = const FixedFeatureFlags({}),
  })  : _inBackground = flags.isEnabled(Feature.backgroundSync),
        super(LoanerInitial()) {
    _filtersController = StreamController<_LoanerFilters>.broadcast(sync: true)
      ..add(const _LoanerFilters());

    _loanerSubscription = _filtersController.stream
        .switchMap(
      (filters) => _repository.watchLoaners(
        searchQuery: filters.searchQuery,
        customerFilter: filters.loanerFilter,
        fromDate: filters.fromDate,
        toDate: filters.toDate,
      ),
    )
        .listen((items) {
      if (!isClosed) {
        add(_LoanerUpdatedFromLocal(items));
      }
    });

    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isOnline) {
        if (!isClosed) {
          add(_LoanerConnectivityChanged(isOnline: isOnline));
        }
      },
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

  /// Saves return at once and sync in the background: no overlay, and
  /// no claim about the server in the message.
  final bool _inBackground;
  final LoanerRepository _repository;
  // The one place loaner reaches past its own repository: a loan
  // response carries its customer, and caching that is customer's job.
  final RefreshLoanersUseCase _refreshLoaners;
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
    if (isClosed) {
      return;
    }

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
    final hasCachedItems = await _repository.hasCachedLoaners(
      searchQuery: newSearchQuery,
      customerFilter: newLoanerFilter,
      fromDate: newFromDate,
      toDate: newToDate,
    );
    final isOnline = await _connectivityService.isOnline;

    if (isClosed) {
      return;
    }

    if (isFilterChange) {
      if (!_filtersController.isClosed) {
        _filtersController.add(
          _LoanerFilters(
            searchQuery: newSearchQuery,
            fromDate: newFromDate,
            toDate: newToDate,
            loanerFilter: newLoanerFilter,
          ),
        );
      }
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

    final result = await _refreshLoaners(
      limit: newLimit,
      page: effectivePage,
      searchQuery: newSearchQuery,
      customer: newLoanerFilter?.id.toString(),
      fromDate: newFromDate,
      toDate: newToDate,
    );

    if (isClosed) {
      return;
    }

    if (result case Ok(:final value)) {
      final latestState = state.asLoaded;
      if (latestState != null) {
        emit(
          latestState.copyWith(
            response: latestState.response.copyWith(
              pagination: value.pagination,
            ),
            searchQuery: newSearchQuery,
            fromDate: newFromDate,
            toDate: newToDate,
            loanerFilter: newLoanerFilter,
            isOffline: false,
            // ignore: avoid_redundant_argument_values -- null clears the banner; omitting it would keep the old one.
            syncMessage: null,
          ),
        );
      } else {
        emit(
          LoanerLoaded(
            value,
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

    emit(
      LoanerError(result.errorOrNull?.message ?? 'Failed to load items.'),
    );
  }

  Future<void> _onAddLoaner(AddLoaner event, Emitter<LoanerState> emit) async {
    if (!_inBackground) LoadingOverlay.show();
    try {
      (await _repository.createLoaner(event.loaner)).fold(
        ok: (loan) => showSuccessSnackBar(
          null,
          syncFeedback(
            loan.syncStatus,
            done: 'Created ${loan.customer?.name}', inBackground: _inBackground),
        ),
        err: (e) =>
            showErrorSnackBar(null, 'Failed to create loaner: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create loaner: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onUpdateLoaner(
    UpdateLoaner event,
    Emitter<LoanerState> emit,
  ) async {
    if (!_inBackground) LoadingOverlay.show();
    try {
      (await _repository.updateLoaner(event.loaner)).fold(
        ok: (loan) => showSuccessSnackBar(
          null,
          syncFeedback(
            loan.syncStatus,
            done: 'Updated ${loan.customer?.name}', inBackground: _inBackground),
        ),
        err: (e) =>
            showErrorSnackBar(null, 'Failed to update loaner: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update loaner: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteLoaner(
    DeleteLoaner event,
    Emitter<LoanerState> emit,
  ) async {
    if (!_inBackground) LoadingOverlay.show();
    try {
      (await _repository.deleteLoaner(event.body)).fold(
        ok: (_) => showSuccessSnackBar(
          null,
          'Deleted ${event.body.customer?.name}',
        ),
        err: (e) =>
            showErrorSnackBar(null, 'Failed to delete loaner: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete loaner: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onConnectivityChanged(
    _LoanerConnectivityChanged event,
    Emitter<LoanerState> emit,
  ) async {
    if (isClosed) {
      return;
    }

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

    await _repository.syncPendingChanges();
    final result = await _refreshLoaners(
      limit: currentState.pagination.limit,
      page: currentState.pagination.page,
      searchQuery: currentState.searchQuery,
      customer: currentState.loanerFilter?.id.toString(),
      fromDate: currentState.fromDate,
      toDate: currentState.toDate,
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
          response: latestState.response.copyWith(
            pagination: value.pagination,
          ),
          isOffline: false,
          // ignore: avoid_redundant_argument_values -- null clears the banner; omitting it would keep the old one.
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

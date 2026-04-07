import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/income/income.dart';
import 'package:stream_transform/stream_transform.dart';

part 'income_event.dart';
part 'income_state.dart';

const _incomeDateUnset = Object();
const _incomeBankUnset = Object();
const _incomeRecordUnset = Object();
const _incomeStatusUnset = Object();

extension IncomeStateExtension on IncomeState {
  IncomeLoaded? get asLoaded =>
      this is IncomeLoaded ? this as IncomeLoaded : null;
}

class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  IncomeBloc(this._service) : super(const IncomeLoading()) {
    _filtersController = StreamController<_IncomeFilters>.broadcast(sync: true);

    _incomeSubscription = _filtersController.stream
        .debounce(const Duration(milliseconds: 150))
        .switchMap(
          (filters) => _service.watchNotifications(
            searchQuery: filters.searchQuery,
            fromDate: filters.fromDate,
            toDate: filters.toDate,
            bankFilter: filters.bankFilter,
            recordFilter: filters.recordFilter,
          ),
        )
        .listen((items) => add(_IncomeUpdated(items)));
    _filtersController.add(const _IncomeFilters());

    on<LoadIncomeDashboard>(_onLoadIncomeDashboard);
    on<_IncomeUpdated>(_onIncomeUpdated);
    on<_IncomeBootstrapCompleted>(_onIncomeBootstrapCompleted);
    on<RefreshIncomeTrackingStatus>(_onRefreshIncomeTrackingStatus);
    on<OpenNotificationAccessSettings>(_onOpenNotificationAccessSettings);
    on<SeedIncomeDemoData>(_onSeedIncomeDemoData);

    unawaited(_bootstrap());
  }

  final IncomeService _service;
  late final StreamController<_IncomeFilters> _filtersController;
  late final StreamSubscription<List<BankNotificationModel>>
      _incomeSubscription;

  @override
  Future<void> close() async {
    await _incomeSubscription.cancel();
    await _filtersController.close();
    await _service.dispose();
    return super.close();
  }

  Future<void> _bootstrap() async {
    await _service.initialize();
    final status = await _service.getTrackingStatus();
    add(_IncomeBootstrapCompleted(status));
  }

  Future<void> _onLoadIncomeDashboard(
    LoadIncomeDashboard event,
    Emitter<IncomeState> emit,
  ) async {
    final currentState = state.asLoaded;
    final searchQuery = event.searchQuery ?? currentState?.searchQuery ?? '';
    final fromDate = identical(event.fromDate, _incomeDateUnset)
        ? currentState?.fromDate
        : event.fromDate as DateTime?;
    final toDate = identical(event.toDate, _incomeDateUnset)
        ? currentState?.toDate
        : event.toDate as DateTime?;
    final bankFilter = identical(event.bankFilter, _incomeBankUnset)
        ? currentState?.bankFilter
        : event.bankFilter as BankApp?;
    final recordFilter = identical(event.recordFilter, _incomeRecordUnset)
        ? currentState?.recordFilter ?? NotificationRecordFilter.all
        : event.recordFilter as NotificationRecordFilter? ??
            NotificationRecordFilter.all;

    _filtersController.add(
      _IncomeFilters(
        searchQuery: searchQuery,
        fromDate: fromDate,
        toDate: toDate,
        bankFilter: bankFilter,
        recordFilter: recordFilter,
      ),
    );

    if (currentState == null) {
      emit(const IncomeLoading());
      return;
    }

    emit(
      currentState.copyWith(
        searchQuery: searchQuery,
        fromDate: fromDate,
        toDate: toDate,
        bankFilter: bankFilter,
        recordFilter: recordFilter,
      ),
    );
  }

  void _onIncomeUpdated(
    _IncomeUpdated event,
    Emitter<IncomeState> emit,
  ) {
    final currentState = state.asLoaded;
    emit(
      IncomeLoaded(
        items: event.items,
        searchQuery: currentState?.searchQuery ?? '',
        fromDate: currentState?.fromDate,
        toDate: currentState?.toDate,
        bankFilter: currentState?.bankFilter,
        recordFilter:
            currentState?.recordFilter ?? NotificationRecordFilter.all,
        trackingStatus: currentState?.trackingStatus,
      ),
    );
  }

  void _onIncomeBootstrapCompleted(
    _IncomeBootstrapCompleted event,
    Emitter<IncomeState> emit,
  ) {
    final currentState = state.asLoaded;
    emit(
      IncomeLoaded(
        items: currentState?.items ?? const [],
        searchQuery: currentState?.searchQuery ?? '',
        fromDate: currentState?.fromDate,
        toDate: currentState?.toDate,
        bankFilter: currentState?.bankFilter,
        recordFilter:
            currentState?.recordFilter ?? NotificationRecordFilter.all,
        trackingStatus: event.status,
      ),
    );
  }

  Future<void> _onRefreshIncomeTrackingStatus(
    RefreshIncomeTrackingStatus event,
    Emitter<IncomeState> emit,
  ) async {
    await _service.importPendingTrackedNotifications();
    final status = await _service.getTrackingStatus();
    add(_IncomeBootstrapCompleted(status));
  }

  Future<void> _onOpenNotificationAccessSettings(
    OpenNotificationAccessSettings event,
    Emitter<IncomeState> emit,
  ) async {
    await _service.openNotificationAccessSettings();
  }

  Future<void> _onSeedIncomeDemoData(
    SeedIncomeDemoData event,
    Emitter<IncomeState> emit,
  ) async {
    final seeded = await _service.seedDemoNotifications();
    if (!seeded) {
      showErrorSnackBar(null, event.blockedMessage);
      add(const RefreshIncomeTrackingStatus());
      return;
    }

    showSuccessSnackBar(null, event.successMessage);
  }
}

class _IncomeFilters {
  const _IncomeFilters({
    this.searchQuery = '',
    this.fromDate,
    this.toDate,
    this.bankFilter,
    this.recordFilter = NotificationRecordFilter.all,
  });

  final String searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final BankApp? bankFilter;
  final NotificationRecordFilter recordFilter;
}

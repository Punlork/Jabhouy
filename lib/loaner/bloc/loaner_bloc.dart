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
  LoanerLoaded? get asLoaded => this is LoanerLoaded ? this as LoanerLoaded : null;
}

class LoanerBloc extends Bloc<LoanerEvent, LoanerState> {
  LoanerBloc(this._service) : super(LoanerInitial()) {
    on<LoadLoaners>(
      _onLoadLoaners,
      transformer: (events, mapper) {
        final searchEvents = events.where((e) => e.isSearch).debounce(throttleDuration);
        final scrollEvents = events.where((e) => !e.isSearch).throttle(throttleDuration);
        return droppable<LoadLoaners>().call(
          searchEvents.merge(scrollEvents),
          mapper,
        );
      },
    );
    on<AddLoaner>(_onAddLoaner);
    on<UpdateLoaner>(_onUpdateLoaner);
    on<DeleteLoaner>(_onDeleteLoaner);
  }
  static const throttleDuration = Duration(milliseconds: 300);

  final LoanerService _service;

  Future<void> _onLoadLoaners(LoadLoaners event, Emitter<LoanerState> emit) async {
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
    final showFilterLoading = effectivePage == 1 && isFilterChange;

    if (state is LoanerInitial || (event.forceRefresh && effectivePage == 1) || showFilterLoading) {
      emit(const LoanerLoading());
    }

    try {
      final response = await _service.getLoaners(
        limit: newLimit,
        page: effectivePage,
        searchQuery: newSearchQuery,
        customer: newLoanerFilter?.id.toString(),
        fromDate: newFromDate,
        toDate: newToDate,
      );

      if (response.success && response.data != null) {
        final paginatedItems = response.data!.items;
        final pagination = response.data!.pagination;

        var allItems = <LoanerModel>[];
        if (event.forceRefresh || isFilterChange || effectivePage == 1) {
          allItems = paginatedItems;
        } else if (currentState != null) {
          allItems = [...currentState.items, ...paginatedItems];
        } else {
          allItems = paginatedItems;
        }

        emit(
          LoanerLoaded(
            PaginatedResponse(items: allItems, pagination: pagination),
            searchQuery: newSearchQuery,
            fromDate: newFromDate,
            toDate: newToDate,
            loanerFilter: newLoanerFilter,
          ),
        );
      }
    } catch (e) {
      emit(LoanerError('Failed to load items: $e'));
    }
  }

  Future<void> _onAddLoaner(AddLoaner event, Emitter<LoanerState> emit) async {
    LoadingOverlay.show();
    try {
      final currentState = state.asLoaded;
      if (currentState == null) return;
      final response = await _service.createLoaner(event.loaner);

      if (!response.success) return;

      showSuccessSnackBar(null, 'Created ${response.data?.customer?.name}');

      final updateLoaners = [response.data!, ...currentState.response.items];

      emit(
        currentState.copyWith(
          response: currentState.response.copyWith(
            items: updateLoaners,
          ),
        ),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create loaner: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onUpdateLoaner(UpdateLoaner event, Emitter<LoanerState> emit) async {
    LoadingOverlay.show();
    try {
      final currentState = state.asLoaded;
      if (currentState == null) return;
      final response = await _service.updateLoaner(event.loaner);
      if (!response.success) return;
      showSuccessSnackBar(null, 'Updated ${response.data?.customer?.name}');

      final updateLoaners = currentState.response.items
          .map(
            (loaner) => loaner.id == event.loaner.id ? response.data! : loaner,
          )
          .toList();

      emit(
        currentState.copyWith(
          response: currentState.response.copyWith(items: updateLoaners),
        ),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update loaner: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteLoaner(DeleteLoaner event, Emitter<LoanerState> emit) async {
    LoadingOverlay.show();
    try {
      final currentState = state.asLoaded;

      if (currentState == null) return;

      final response = await _service.deleteLoaner(event.body);

      if (!response.success) return;

      showSuccessSnackBar(null, 'Deleted ${event.body.customer?.name}');

      final updatedLoaner = List<LoanerModel>.from(
        currentState.response.items,
      )..removeWhere(
          (item) => item.id == event.body.id,
        );

      emit(
        currentState.copyWith(
          response: currentState.response.copyWith(
            items: updatedLoaner,
          ),
        ),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete loaner: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }
}

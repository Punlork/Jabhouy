// ignore_for_file: inference_failure_on_instance_creation

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/loaner/loaner.dart';

part 'loaner_event.dart';
part 'loaner_state.dart';

extension ShopStateExtension on LoanerState {
  LoanerLoaded? get asLoaded => this is LoanerLoaded ? this as LoanerLoaded : null;
}

class LoanerBloc extends Bloc<LoanerEvent, LoanerState> {
  LoanerBloc(this._service) : super(LoanerInitial()) {
    on<LoadLoaners>(_onLoadLoaners);
    on<AddLoaner>(_onAddLoaner);
    on<UpdateLoaner>(_onUpdateLoaner);
    on<DeleteLoaner>(_onDeleteLoaner);
  }

  final LoanerService _service;

  Future<void> _onLoadLoaners(LoadLoaners event, Emitter<LoanerState> emit) async {
    emit(LoanerLoading());
    try {
      final response = await _service.getLoaners();
      if (!response.success) return;
      emit(LoanerLoaded(response.data!));
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

      showSuccessSnackBar(null, 'Created ${response.data?.name}');

      final updateLoaners = [response.data!, ...currentState.loaners];

      emit(LoanerLoaded(updateLoaners));
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
      showSuccessSnackBar(null, 'Updated ${response.data?.name}');

      final updateLoaners = currentState.loaners
          .map(
            (loaner) => loaner.id == event.loaner.id ? response.data! : loaner,
          )
          .toList();

      emit(LoanerLoaded(updateLoaners));
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

      showSuccessSnackBar(null, 'Deleted ${event.body.name}');

      final updatedLoaner = List<LoanerModel>.from(
        currentState.loaners,
      )..removeWhere(
          (item) => item.id == event.body.id,
        );

      emit(LoanerLoaded(updatedLoaner));
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete loaner: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }
}

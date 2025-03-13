// ignore_for_file: inference_failure_on_instance_creation

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/loaner/loaner.dart';

part 'loaner_event.dart';
part 'loaner_state.dart';

class LoanerBloc extends Bloc<LoanerEvent, LoanerState> {
  LoanerBloc() : super(LoanerInitial()) {
    on<LoadLoaners>(_onLoadLoaners);
    on<AddLoaner>(_onAddLoaner);
    on<UpdateLoaner>(_onUpdateLoaner);
    on<DeleteLoaner>(_onDeleteLoaner);
  }

  // Dummy data store
  final List<LoanerModel> _dummyLoaners = [
    const LoanerModel(
      id: '1', name: 'John Doe', amount: 500, note: 'Beer',
      // dueDate: DateTime.now().add(const Duration(days: 30)),
    ),
    const LoanerModel(
      id: '2', name: 'Jane Smith', amount: 750, note: 'Cig',
      // dueDate: DateTime.now().add(const Duration(days: 15)),
    ),
    const LoanerModel(
      id: '3', name: 'Bob Johnson', amount: 300, note: 'Beer',
      // dueDate: DateTime.now().add(const Duration(days: 45)),
    ),
  ];

  Future<void> _onLoadLoaners(LoadLoaners event, Emitter<LoanerState> emit) async {
    emit(LoanerLoading());
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    emit(LoanerLoaded(List.from(_dummyLoaners)));
  }

  Future<void> _onAddLoaner(AddLoaner event, Emitter<LoanerState> emit) async {
    final currentState = state;
    if (currentState is LoanerLoaded) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      _dummyLoaners.add(event.loaner);
      emit(LoanerLoaded(List.from(_dummyLoaners)));
    }
  }

  Future<void> _onUpdateLoaner(UpdateLoaner event, Emitter<LoanerState> emit) async {
    final currentState = state;
    if (currentState is LoanerLoaded) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _dummyLoaners.indexWhere((loaner) => loaner.id == event.loaner.id);
      if (index != -1) {
        _dummyLoaners[index] = event.loaner;
        emit(LoanerLoaded(List.from(_dummyLoaners)));
      } else {
        emit(const LoanerError('Loaner not found'));
      }
    }
  }

  Future<void> _onDeleteLoaner(DeleteLoaner event, Emitter<LoanerState> emit) async {
    final currentState = state;
    if (currentState is LoanerLoaded) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      _dummyLoaners.removeWhere((loaner) => loaner.id == event.id);
      emit(LoanerLoaded(List.from(_dummyLoaners)));
    }
  }
}

part of 'loaner_bloc.dart';

abstract class LoanerEvent extends Equatable {
  const LoanerEvent();

  @override
  List<Object> get props => [];
}

class LoadLoaners extends LoanerEvent {}

class AddLoaner extends LoanerEvent {
  const AddLoaner(this.loaner);
  final LoanerModel loaner;

  @override
  List<Object> get props => [loaner];
}

class UpdateLoaner extends LoanerEvent {
  const UpdateLoaner(this.loaner);
  final LoanerModel loaner;

  @override
  List<Object> get props => [loaner];
}

class DeleteLoaner extends LoanerEvent {
  const DeleteLoaner(this.id);
  final String id;

  @override
  List<Object> get props => [id];
}

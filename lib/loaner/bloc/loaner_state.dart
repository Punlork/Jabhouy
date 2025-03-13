part of 'loaner_bloc.dart';

abstract class LoanerState extends Equatable {
  const LoanerState();

  @override
  List<Object> get props => [];
}

class LoanerInitial extends LoanerState {}

class LoanerLoading extends LoanerState {}

class LoanerLoaded extends LoanerState {
  const LoanerLoaded(this.loaners);
  final List<LoanerModel> loaners;

  @override
  List<Object> get props => [loaners];
}

class LoanerError extends LoanerState {
  const LoanerError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

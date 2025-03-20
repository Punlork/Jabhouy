part of 'loaner_bloc.dart';

abstract class LoanerEvent extends Equatable {
  const LoanerEvent();

  @override
  List<Object> get props => [];
}

class LoadLoaners extends LoanerEvent {
  LoadLoaners({
    this.limit,
    this.page,
    this.fromDate,
    this.toDate,
    this.searchQuery,
    this.forceRefresh = false,
    this.loanerFilter,
  }) : isSearch = searchQuery != null && searchQuery.isNotEmpty;

  final String? searchQuery;
  final int? limit;
  final int? page;
  final bool forceRefresh;
  final bool isSearch;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? loanerFilter;
}

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
  const DeleteLoaner(this.body);
  final LoanerModel body;

  @override
  List<Object> get props => [body];
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'loaner_bloc.dart';

abstract class LoanerState extends Equatable {
  const LoanerState();

  @override
  List<Object?> get props => [];
}

class LoanerInitial extends LoanerState {}

class LoanerLoading extends LoanerState {
  const LoanerLoading();
}

@CopyWith()
class LoanerLoaded extends LoanerState {
  final PaginatedResponse<LoanerModel> response;
  final String searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final CustomerModel? loanerFilter;
  final bool isOffline;
  final String? syncMessage;

  bool get hasFilter {
    return searchQuery.isNotEmpty ||
        (fromDate != null && toDate != null) ||
        loanerFilter != null;
  }

  const LoanerLoaded(
    this.response, {
    this.searchQuery = '',
    this.fromDate,
    this.toDate,
    this.loanerFilter,
    this.isOffline = false,
    this.syncMessage,
  });

  List<LoanerModel> get items => response.items;
  Pagination get pagination => response.pagination;

  @override
  List<Object?> get props => [
        response,
        searchQuery,
        fromDate,
        toDate,
        loanerFilter,
        isOffline,
        syncMessage,
      ];
}

class LoanerError extends LoanerState {
  const LoanerError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

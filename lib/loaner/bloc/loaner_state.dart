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

class LoanerLoaded extends LoanerState {
  final PaginatedResponse<LoanerModel> response;
  final String searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final CustomerModel? loanerFilter;

  bool get hasFilter {
    return searchQuery.isNotEmpty || (fromDate != null && toDate != null) || loanerFilter != null;
  }

  const LoanerLoaded(
    this.response, {
    this.searchQuery = '',
    this.fromDate,
    this.toDate,
    this.loanerFilter,
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
      ];

  LoanerLoaded copyWith({
    PaginatedResponse<LoanerModel>? response,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    CustomerModel? loanerFilter,
  }) {
    return LoanerLoaded(
      response ?? this.response,
      searchQuery: searchQuery ?? this.searchQuery,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      loanerFilter: loanerFilter ?? this.loanerFilter,
    );
  }
}

class LoanerError extends LoanerState {
  const LoanerError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

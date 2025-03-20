// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'loaner_bloc.dart';

abstract class LoanerState extends Equatable {
  const LoanerState();

  @override
  List<Object?> get props => [];
}

class LoanerInitial extends LoanerState {}

class LoanerLoading extends LoanerState {}

class LoanerLoaded extends LoanerState {
  const LoanerLoaded({
    required this.response,
    this.searchQuery,
  });
  final PaginatedResponse<LoanerModel> response;
  final String? searchQuery;

  List<LoanerModel> get items => response.items;
  Pagination get pagination => response.pagination;

  @override
  List<Object?> get props => [
        response,
        searchQuery,
      ];

  LoanerLoaded copyWith({
    PaginatedResponse<LoanerModel>? response,
    String? searchQuery,
  }) {
    return LoanerLoaded(
      response: response ?? this.response,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class LoanerError extends LoanerState {
  const LoanerError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

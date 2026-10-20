part of 'credit_list_cubit.dart';

@CopyWith()
class CreditListState extends Equatable {
  const CreditListState({
    this.loading = true,
    this.credits = const [],
    this.summary,
    this.filter = CreditFilter.unpaid,
    this.query = '',
    this.currency = Currency.khr,
  });

  final bool loading;

  /// Narrowed by [filter] and [query]; newest first.
  final List<Credit> credits;

  /// Over every unpaid Credit, whatever the chip or search says.
  final CreditSummary? summary;
  final CreditFilter filter;
  final String query;

  /// The shop's default currency: the rows and summary lead with it.
  final Currency currency;

  @override
  List<Object?> get props => [
    loading,
    credits,
    summary?.total,
    summary?.other,
    summary?.people,
    summary?.peopleWithoutAmount,
    filter,
    query,
    currency,
  ];
}

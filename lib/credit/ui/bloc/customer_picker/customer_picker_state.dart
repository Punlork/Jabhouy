part of 'customer_picker_cubit.dart';

@CopyWith()
class CustomerPickerState extends Equatable {
  const CustomerPickerState({
    this.customers = const [],
    this.query = '',
    this.loading = true,
  });

  final List<CustomerBalance> customers;
  final String query;
  final bool loading;

  @override
  List<Object?> get props => [
    [for (final c in customers) (c.customer.id, c.customer.name, c.owed)],
    [for (final c in customers) (c.unknownCount, c.creditCount)],
    query,
    loading,
  ];
}

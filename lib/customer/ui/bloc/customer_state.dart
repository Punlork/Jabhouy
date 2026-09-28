part of 'customer_bloc.dart';

class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

@CopyWith()
class CustomerLoaded extends CustomerState {
  const CustomerLoaded(
    this.customers, {
    this.isOffline = false,
    this.syncMessage,
  });

  final List<CustomerModel> customers;
  final bool isOffline;
  final String? syncMessage;

  @override
  List<Object?> get props => [customers, isOffline, syncMessage];
}

class CustomerCreated extends CustomerState {
  const CustomerCreated(this.customer);
  final CustomerModel customer;

  @override
  List<Object?> get props => [customer];
}

class CustomerError extends CustomerState {
  const CustomerError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class CustomerDeleted extends CustomerState {
  const CustomerDeleted();
}

class CustomerUpdated extends CustomerState {
  const CustomerUpdated(this.customer);
  final CustomerModel customer;

  @override
  List<Object?> get props => [customer];
}

part of 'customer_bloc.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  const CustomerLoaded(this.customers);
  final List<CustomerModel> customers;
}

class CustomerCreated extends CustomerState {
  const CustomerCreated(this.customer);
  final CustomerModel customer;
}

class CustomerError extends CustomerState {
  const CustomerError(this.message);
  final String message;
}

class CustomerDeleted extends CustomerState {
  const CustomerDeleted();

  @override
  List<Object> get props => [];
}

class CustomerUpdated extends CustomerState {
  const CustomerUpdated(this.customer);
  final CustomerModel customer;

  @override
  List<Object> get props => [customer];
}

part of 'customer_bloc.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object> get props => [];
}

class LoadCustomers extends CustomerEvent {}

class CreateCustomerEvent extends CustomerEvent {
  const CreateCustomerEvent(this.customer);

  final CustomerModel customer;
}

class UpdateCustomerEvent extends CustomerEvent {
  const UpdateCustomerEvent(this.customer);

  final CustomerModel customer;

  @override
  List<Object> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  const DeleteCustomerEvent(this.customer);

  final CustomerModel customer;

  @override
  List<Object> get props => [customer];
}

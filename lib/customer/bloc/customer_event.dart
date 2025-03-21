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

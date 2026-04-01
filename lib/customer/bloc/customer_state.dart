part of 'customer_bloc.dart';

class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  const CustomerLoaded(
    this.customers, {
    this.isOffline = false,
    this.syncMessage,
  });

  final List<CustomerModel> customers;
  final bool isOffline;
  final String? syncMessage;

  CustomerLoaded copyWith({
    List<CustomerModel>? customers,
    bool? isOffline,
    Object? syncMessage = _customerSyncMessageUnset,
  }) {
    return CustomerLoaded(
      customers ?? this.customers,
      isOffline: isOffline ?? this.isOffline,
      syncMessage: identical(syncMessage, _customerSyncMessageUnset)
          ? this.syncMessage
          : syncMessage as String?,
    );
  }

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

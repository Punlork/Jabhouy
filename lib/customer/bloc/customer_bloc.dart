import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/customer/customer.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc(this.customerService) : super(CustomerInitial()) {
    _customerSubscription = customerService.watchCustomers().listen((customers) {
      add(CustomerUpdatedFromLocal(customers));
    });

    on<LoadCustomers>(_onLoadCustomers);
    on<CustomerUpdatedFromLocal>(_onCustomerUpdatedFromLocal);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
  }

  final CustomerService customerService;
  late StreamSubscription<List<CustomerModel>> _customerSubscription;

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    if (state is! CustomerLoaded) {
      emit(CustomerLoading());
    }
    try {
      await customerService.getCustomers();
    } catch (e) {
      if (state is! CustomerLoaded) {
        emit(CustomerError(e.toString()));
      }
    }
  }

  void _onCustomerUpdatedFromLocal(
    CustomerUpdatedFromLocal event,
    Emitter<CustomerState> emit,
  ) {
    emit(CustomerLoaded(event.customers));
  }

  Future<void> _onCreateCustomer(
    CreateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await customerService.createCustomer(event.customer);
    } catch (e) {
      // Errors are handled by showing snackbars in UI or here
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await customerService.updateCustomer(event.customer);
    } catch (e) {
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await customerService.deleteCustomer(event.customer);
    } catch (e) {
    }
  }

  @override
  Future<void> close() {
    _customerSubscription.cancel();
    return super.close();
  }
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/customer/customer.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc(this.customerService) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
  }

  final CustomerService customerService;
  List<CustomerModel> _allCustomers = [];

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final response = await customerService.getCustomers();
      _allCustomers = response.data?.items ?? [];
      emit(CustomerLoaded(_allCustomers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onCreateCustomer(
    CreateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      final response = await customerService.createCustomer(event.customer);
      if (response.data != null) {
        _allCustomers.add(response.data!);
        emit(CustomerCreated(response.data!));
        emit(CustomerLoaded(_allCustomers));
      }
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      final response = await customerService.updateCustomer(event.customer);
      if (response.data != null) {
        final index = _allCustomers.indexWhere((c) => c.id == event.customer.id);
        if (index != -1) {
          _allCustomers[index] = response.data!;
        } else {
          _allCustomers.add(response.data!);
        }
        emit(CustomerUpdated(response.data!));
        emit(CustomerLoaded(_allCustomers));
      }
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await customerService.deleteCustomer(event.customer);
      _allCustomers.removeWhere((c) => c.id == event.customer.id);
      emit(const CustomerDeleted());
      emit(CustomerLoaded(_allCustomers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }
}

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';

part 'customer_event.dart';
part 'customer_state.dart';

const _customerSyncMessageUnset = Object();

extension CustomerStateExtension on CustomerState {
  CustomerLoaded? get asLoaded =>
      this is CustomerLoaded ? this as CustomerLoaded : null;
}

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc(this._repository, this._connectivityService)
      : super(CustomerInitial()) {
    _customerSubscription =
        _repository.watchCustomers().listen((customers) {
      if (!isClosed) {
        add(CustomerUpdatedFromLocal(customers));
      }
    });
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isOnline) {
        if (!isClosed) {
          add(_CustomerConnectivityChanged(isOnline: isOnline));
        }
      },
    );

    on<LoadCustomers>(_onLoadCustomers);
    on<CustomerUpdatedFromLocal>(_onCustomerUpdatedFromLocal);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
    on<_CustomerConnectivityChanged>(_onConnectivityChanged);
  }

  final CustomerRepository _repository;
  final ConnectivityService _connectivityService;
  late StreamSubscription<List<CustomerModel>> _customerSubscription;
  late StreamSubscription<bool> _connectivitySubscription;

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    final currentState = state.asLoaded;
    final hasCachedItems = await _repository.hasCachedCustomers();
    final isOnline = await _connectivityService.isOnline;

    if (state is! CustomerLoaded && !hasCachedItems) {
      emit(CustomerLoading());
    }

    if (!isOnline) {
      if (currentState != null) {
        emit(
          currentState.copyWith(
            isOffline: true,
            syncMessage: _offlineMessage(hasCachedItems),
          ),
        );
      } else if (!hasCachedItems) {
        emit(
          const CustomerError(
            'You are offline and there is no cached customer data yet.',
          ),
        );
      }
      return;
    }

    final response = await _repository.refreshCustomers();
    if (response.success) {
      final latestState = state.asLoaded;
      if (latestState != null) {
        emit(latestState.copyWith(isOffline: false, syncMessage: null));
      }
      return;
    }

    if (currentState != null || hasCachedItems) {
      final latestState = state.asLoaded;
      if (latestState != null) {
        emit(
          latestState.copyWith(
            isOffline: false,
            syncMessage: 'Failed to refresh. Showing cached customers.',
          ),
        );
      }
      return;
    }

    emit(CustomerError(response.message ?? 'Failed to load customers.'));
  }

  void _onCustomerUpdatedFromLocal(
    CustomerUpdatedFromLocal event,
    Emitter<CustomerState> emit,
  ) {
    final currentState = state.asLoaded;
    emit(
      CustomerLoaded(
        event.customers,
        isOffline: currentState?.isOffline ?? false,
        syncMessage: currentState?.syncMessage,
      ),
    );
  }

  Future<void> _onCreateCustomer(
    CreateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    final response = await _repository.createCustomer(event.customer);
    if (!response.success) {
      emit(CustomerError(response.message ?? 'Failed to create customer.'));
      return;
    }
    final currentState = state.asLoaded;
    if (currentState != null && response.message != null) {
      emit(currentState.copyWith(syncMessage: response.message));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    final response = await _repository.updateCustomer(event.customer);
    if (!response.success) {
      emit(CustomerError(response.message ?? 'Failed to update customer.'));
      return;
    }
    final currentState = state.asLoaded;
    if (currentState != null && response.message != null) {
      emit(currentState.copyWith(syncMessage: response.message));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    final response = await _repository.deleteCustomer(event.customer);
    if (!response.success) {
      emit(CustomerError(response.message ?? 'Failed to delete customer.'));
      return;
    }
    final currentState = state.asLoaded;
    if (currentState != null && response.message != null) {
      emit(currentState.copyWith(syncMessage: response.message));
    }
  }

  Future<void> _onConnectivityChanged(
    _CustomerConnectivityChanged event,
    Emitter<CustomerState> emit,
  ) async {
    final currentState = state.asLoaded;
    if (currentState == null) {
      return;
    }

    if (!event.isOnline) {
      emit(
        currentState.copyWith(
          isOffline: true,
          syncMessage: _offlineMessage(currentState.customers.isNotEmpty),
        ),
      );
      return;
    }

    emit(
      currentState.copyWith(
        isOffline: false,
        syncMessage: 'Back online. Syncing customers...',
      ),
    );

    await _repository.syncPendingChanges();
    final response = await _repository.refreshCustomers();
    final latestState = state.asLoaded;
    if (latestState == null) {
      return;
    }

    if (response.success) {
      emit(latestState.copyWith(isOffline: false, syncMessage: null));
      return;
    }

    emit(
      latestState.copyWith(
        isOffline: false,
        syncMessage: 'Back online, but customer refresh failed.',
      ),
    );
  }

  String _offlineMessage(bool hasCachedItems) {
    if (hasCachedItems) {
      return 'Offline - showing cached customers.';
    }
    return 'Offline - connect once to cache customers.';
  }

  @override
  Future<void> close() {
    _customerSubscription.cancel();
    _connectivitySubscription.cancel();
    return super.close();
  }
}

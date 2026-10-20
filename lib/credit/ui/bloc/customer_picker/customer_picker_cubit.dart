import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy/credit/data/credit_repository.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

part 'customer_picker_state.dart';
part 'customer_picker_cubit.g.dart';

/// The customer picker (canvas ១១): the Shop's Customers with what each
/// owes, narrowed by search. The only place a Customer is added, renamed
/// or deleted (decisions 10 and 33).
class CustomerPickerCubit extends Cubit<CustomerPickerState> {
  CustomerPickerCubit(this._repository) : super(const CustomerPickerState());

  final CreditRepository _repository;
  StreamSubscription<List<CustomerBalance>>? _subscription;

  bool get canDelete => _repository.canDelete;

  void start() => _watch();

  void search(String query) {
    emit(state.copyWith(query: query));
    _watch();
  }

  /// Adds a Customer, or renames the one with [id].
  Future<Result<CreditCustomer>> save(String name, {String? id}) =>
      _repository.saveCustomer(CreditCustomer(id: id ?? newId(), name: name));

  /// Refused while the Customer has any Credit.
  Future<Result<void>> delete(String id) => _repository.deleteCustomer(id);

  void _watch() {
    unawaited(_subscription?.cancel());
    _subscription = _repository
        .watchCustomers(search: state.query)
        .listen(
          (customers) =>
              emit(state.copyWith(customers: customers, loading: false)),
        );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

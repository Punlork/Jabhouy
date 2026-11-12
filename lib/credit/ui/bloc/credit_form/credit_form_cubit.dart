import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy/credit/data/credit_repository.dart';
import 'package:jabhouy/credit/logic/credit_money.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

part 'credit_form_state.dart';
part 'credit_form_cubit.g.dart';

/// Add or edit a Credit (canvas ៩, ៩ខ, ១០). A new one takes the shop's
/// currency and rate; an edited one keeps the rate it was made at.
class CreditFormCubit extends Cubit<CreditFormState> {
  CreditFormCubit(
    this._repository, {
    this.existing,
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock,
       super(
         existing == null
             ? CreditFormState(takenAt: clock().toUtc())
             : CreditFormState(
                 status: CreditFormStatus.ready,
                 customer: CreditCustomer(
                   id: existing.customerId,
                   name: existing.customerName,
                 ),
                 lines: existing.lines,
                 currency: existing.currency,
                 amount: existing.lines.isEmpty ? existing.amount : null,
                 khrPerUsd: existing.khrPerUsd,
                 takenAt: existing.takenAt,
                 dueDate: existing.dueDate == null
                     ? null
                     : DateTime.parse(existing.dueDate!),
                 creditStatus: existing.status,
               ),
       );

  final CreditRepository _repository;
  final DateTime Function() _clock;

  /// The Credit being edited; null when adding.
  final Credit? existing;

  Future<void> load() async {
    if (existing != null) return;
    final rates = await _repository.currentRates();
    emit(
      state.copyWith(
        status: CreditFormStatus.ready,
        currency: rates.currency,
        khrPerUsd: rates.khrPerUsd,
        takenAt: _clock().toUtc(),
      ),
    );
  }

  void setCustomer(CreditCustomer customer) =>
      emit(state.copyWith(customer: customer, customerMissing: false));

  /// The whole set from the item picker. With lines the amount is their
  /// sum, so a typed one is dropped.
  void setLines(List<CreditLine> lines) => emit(
    state.copyWith(lines: lines, amount: lines.isEmpty ? state.amount : null),
  );

  void setQty(String lineId, int qty) {
    final lines = [
      for (final l in state.lines)
        if (l.id != lineId)
          l
        else if (qty > 0)
          CreditLine(
            id: l.id,
            priceId: l.priceId,
            name: l.name,
            unit: l.unit,
            qty: qty,
            currency: l.currency,
            unitPrice: l.unitPrice,
          ),
    ];
    emit(state.copyWith(lines: lines));
  }

  /// A typed amount and its currency, from the money field.
  void setTyped(int? amount, Currency currency) =>
      emit(state.copyWith(amount: amount, currency: currency));

  /// Switches the Credit's currency when it has lines (they re-convert).
  void setCurrency(Currency currency) =>
      emit(state.copyWith(currency: currency));

  void setTakenAt(DateTime utc) => emit(state.copyWith(takenAt: utc.toUtc()));

  void setDueDate(DateTime? day) =>
      // An explicit null clears the date.
      emit(state.copyWith(dueDate: day));

  void setStatus(CreditStatus status) =>
      emit(state.copyWith(creditStatus: status));

  Future<void> save(String note) async {
    final customer = state.customer;
    if (customer == null) {
      emit(state.copyWith(customerMissing: true));
      return;
    }
    // ignore: avoid_redundant_argument_values -- null clears an old error; omitting it would keep it.
    emit(state.copyWith(error: null));
    final trimmed = note.trim();
    final result = await _repository.saveCredit(
      Credit(
        id: existing?.id ?? newId(),
        customerId: customer.id,
        currency: state.currency,
        amount: state.lines.isEmpty ? state.amount : null,
        khrPerUsd: state.khrPerUsd,
        status: state.creditStatus,
        takenAt: state.takenAt,
        dueDate: state.dueDate?.toIsoDate(),
        paidAt: existing?.paidAt,
        note: trimmed.isEmpty ? null : trimmed,
        lines: state.lines,
      ),
    );
    switch (result) {
      case Ok():
        emit(state.copyWith(status: CreditFormStatus.saved));
      case Err(:final error):
        emit(state.copyWith(error: error.message));
    }
  }
}

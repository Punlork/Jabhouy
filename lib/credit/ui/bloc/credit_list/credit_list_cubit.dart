import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy/credit/data/credit_repository.dart';
import 'package:jabhouy/credit/logic/credit_money.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart' show normalizeSearch;

part 'credit_list_state.dart';
part 'credit_list_cubit.g.dart';

/// The Credit tab: every Credit read once, then narrowed in memory by the
/// chip and the customer search, with the summary over all unpaid ones.
class CreditListCubit extends Cubit<CreditListState> {
  CreditListCubit(this._repository) : super(const CreditListState());

  final CreditRepository _repository;

  StreamSubscription<List<Credit>>? _subscription;
  List<Credit> _all = const [];

  /// Starts reading once the Current Shop is known (after sign-in).
  void start() {
    if (!_repository.ready || _subscription != null) return;
    _subscription = _repository
        .watchCredits(filter: CreditFilter.all)
        .listen((all) async {
          _all = all;
          final rates = await _repository.currentRates();
          emit(_derive(state.copyWith(currency: rates.currency, loading: false)));
        });
  }

  /// On sign-out: drops the Shop's data; [start] reads again later.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _all = const [];
    emit(const CreditListState());
  }

  /// With its lines, for the details sheet; null once deleted.
  Future<Credit?> credit(String id) => _repository.credit(id);

  Future<void> markPaid(String id) => _repository.markPaid(id);

  Future<void> delete(String id) => _repository.deleteCredit(id);

  /// Owner and editor only (decision 14).
  bool get canDelete => _repository.canDelete;

  /// Pull to refresh.
  Future<void> refresh() => _repository.pullLatest();

  void search(String query) => emit(_derive(state.copyWith(query: query)));

  void filter(CreditFilter filter) =>
      emit(_derive(state.copyWith(filter: filter)));

  CreditListState _derive(CreditListState next) {
    final query = normalizeSearch(next.query);
    return next.copyWith(
      credits: [
        for (final credit in _all)
          if ((next.filter == CreditFilter.all ||
                  credit.isPaid == (next.filter == CreditFilter.paid)) &&
              (query.isEmpty ||
                  normalizeSearch(credit.customerName).contains(query)))
            credit,
      ],
      summary: summarize(
        _all.where((credit) => !credit.isPaid),
        next.currency,
      ),
    );
  }

  @override
  Future<void> close() async {
    await stop();
    return super.close();
  }
}

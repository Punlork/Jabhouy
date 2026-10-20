import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';

part 'item_picker_state.dart';
part 'item_picker_cubit.g.dart';

/// The item picker (canvas ៩ក): the Shop's Items, every Price option as
/// its own row with a count. Picking snapshots name, unit, price and
/// currency into a [CreditLine]; a line already on the Credit keeps its
/// own snapshot, so editing a count never reprices it.
class ItemPickerCubit extends Cubit<ItemPickerState> {
  ItemPickerCubit(this._repository, {List<CreditLine> initial = const []})
    : _initial = initial,
      super(
        ItemPickerState(
          quantities: {
            for (final l in initial)
              if (l.priceId != null) l.priceId!: l.qty,
          },
        ),
      );

  final ItemRepository _repository;
  final List<CreditLine> _initial;

  final _subscriptions = <StreamSubscription<Object?>>[];
  List<Item> _all = const [];

  void start() {
    if (_subscriptions.isNotEmpty) return;
    _subscriptions
      ..add(
        _repository.watchItems().listen((items) {
          _all = items;
          emit(_derive(state.copyWith(loading: false)));
        }),
      )
      ..add(
        _repository.watchCategories().listen(
          (categories) => emit(state.copyWith(categories: categories)),
        ),
      );
  }

  void search(String query) => emit(_derive(state.copyWith(query: query)));

  /// Null is `ទាំងអស់`.
  void selectCategory(String? id) =>
      emit(_derive(state.copyWith(categoryId: id)));

  void setQty(String priceId, int qty) {
    final next = {...state.quantities};
    if (qty <= 0) {
      next.remove(priceId);
    } else {
      next[priceId] = qty;
    }
    emit(_derive(state.copyWith(quantities: next)));
  }

  ItemPickerState _derive(ItemPickerState next) {
    final category = next.categoryId;
    final inCategory = category == null
        ? _all
        : [
            for (final i in _all)
              if (i.categoryId == category) i,
          ];
    final query = next.query;
    return next.copyWith(
      items: normalizeSearch(query).isEmpty
          ? inCategory
          : [for (final hit in searchItems(inCategory, query)) hit.item],
      lines: _lines(next.quantities),
    );
  }

  /// A line per chosen option that still exists with a price, keeping the
  /// snapshot (and id) of a line already on the Credit; then the old
  /// lines whose option is gone, untouched.
  List<CreditLine> _lines(Map<String, int> quantities) {
    final before = {
      for (final l in _initial)
        if (l.priceId != null) l.priceId!: l,
    };
    final lines = <CreditLine>[];
    final existing = <String>{};
    for (final item in _all) {
      for (final option in item.prices) {
        existing.add(option.id);
        final qty = quantities[option.id];
        if (qty == null) continue;
        final old = before[option.id];
        if (old != null) {
          lines.add(_withQty(old, qty));
        } else if (option.price != null) {
          lines.add(
            CreditLine(
              id: newId(),
              priceId: option.id,
              name: item.name,
              unit: option.label,
              qty: qty,
              currency: option.currency,
              unitPrice: option.price!,
            ),
          );
        }
      }
    }
    return [
      ...lines,
      for (final old in _initial)
        if (old.priceId == null || !existing.contains(old.priceId)) old,
    ];
  }

  CreditLine _withQty(CreditLine l, int qty) => CreditLine(
    id: l.id,
    priceId: l.priceId,
    name: l.name,
    unit: l.unit,
    qty: qty,
    currency: l.currency,
    unitPrice: l.unitPrice,
  );

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }
}

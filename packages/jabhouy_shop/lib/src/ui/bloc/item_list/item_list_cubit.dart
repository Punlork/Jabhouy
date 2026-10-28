import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/src/data/item_repository.dart';
import 'package:jabhouy_shop/src/logic/item_search.dart';
import 'package:jabhouy_shop/src/models/item.dart';

part 'item_list_state.dart';
part 'item_list_cubit.g.dart';

/// Home's item list: the Current Shop's Items, narrowed by search, a
/// category or the missing-price chip, with list or grid layout.
class ItemListCubit extends Cubit<ItemListState> {
  ItemListCubit(
    this._repository,
    this._scope, {
    bool grid = false,
    this.onGridChanged,
    ItemSort sort = ItemSort.name,
    this.onSortChanged,
  }) : super(
         ItemListState(
           grid: grid,
           sort: sort,
           canEdit: _scope.role?.canEditPrices ?? false,
         ),
       );

  final ItemRepository _repository;
  final ShopScope _scope;

  /// Lets the app remember the layout; this package keeps no storage.
  final ValueChanged<bool>? onGridChanged;

  /// Same for the sort order.
  final ValueChanged<ItemSort>? onSortChanged;

  final _subscriptions = <StreamSubscription<Object?>>[];
  StreamSubscription<List<Item>>? _items;

  /// The category/chip-filtered Items; a search ranks these in memory.
  List<Item> _filtered = const [];

  /// Starts reading once the Current Shop is known (after sign-in).
  void start() {
    if (_scope.shopId == null || _subscriptions.isNotEmpty) return;
    emit(state.copyWith(canEdit: _scope.role?.canEditPrices ?? false));
    // The watch below picks the categories up once they are written.
    unawaited(_repository.seedStarterCategories());
    _subscriptions
      ..add(
        // Live, so a new rate updates every ≈ at once.
        _repository.watchPriceSettings().listen(
          (settings) => emit(state.copyWith(settings: settings)),
        ),
      )
      ..add(
        _repository.watchCategories().listen(
          (categories) => emit(state.copyWith(categories: categories)),
        ),
      )
      ..add(
        _repository.watchRecentItems().listen(
          (items) => emit(state.copyWith(recent: items)),
        ),
      )
      ..add(
        _repository.watchMissingPriceCount().listen(
          (count) => emit(state.copyWith(missingCount: count)),
        ),
      );
    _watchItems();
  }

  /// On sign-out: drops the Shop's data; [start] reads again later.
  Future<void> stop() async {
    await _items?.cancel();
    _items = null;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _filtered = const [];
    emit(ItemListState(grid: state.grid, sort: state.sort));
  }

  void search(String query) {
    emit(_withSearch(state.copyWith(query: query)));
  }

  /// No arguments is `ទាំងអស់`.
  void filter({String? categoryId, bool missingOnly = false}) {
    emit(state.copyWith(categoryId: categoryId, missingOnly: missingOnly));
    _watchItems();
  }

  Future<void> delete(String id) => _repository.deleteItem(id);

  /// Every live Item with a scanned barcode, for the scan result.
  Future<List<Item>> itemsWithBarcode(String code) =>
      _repository.itemsWithBarcode(code);

  /// The details sheet opened [id]: it joins Recently viewed.
  Future<void> viewed(String id) => _repository.recordView(id);

  /// Pull to refresh.
  Future<void> refresh() => _repository.pullLatest();

  /// For the details sheet's "last edited by"; null when unknown.
  Future<String?> editorName(String? userId) async =>
      userId == null ? null : _repository.memberName(userId);

  void toggleGrid() {
    emit(state.copyWith(grid: !state.grid));
    onGridChanged?.call(state.grid);
  }

  void setSort(ItemSort sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    onSortChanged?.call(sort);
    _watchItems();
  }

  /// The DAO reads by name; `recent` re-orders in memory, no date last.
  List<Item> _sorted(List<Item> items) => state.sort == ItemSort.name
      ? items
      : ([...items]..sort((a, b) {
          final x = a.updatedAt;
          final y = b.updatedAt;
          if (x == null || y == null) {
            return x == y ? 0 : (x == null ? 1 : -1);
          }
          return y.compareTo(x);
        }));

  void _watchItems() {
    if (_subscriptions.isEmpty) return;
    unawaited(_items?.cancel());
    _items = _repository
        .watchItems(
          categoryId: state.categoryId,
          missingOnly: state.missingOnly,
        )
        .listen((items) {
          _filtered = _sorted(items);
          emit(_withSearch(state.copyWith(loading: false)));
        });
  }

  /// [next] with `items` and `nicknameMatches` for its query.
  ItemListState _withSearch(ItemListState next) {
    if (normalizeSearch(next.query).isEmpty) {
      return next.copyWith(items: _filtered, nicknameMatches: const {});
    }
    final hits = searchItems(_filtered, next.query);
    return next.copyWith(
      items: [for (final hit in hits) hit.item],
      nicknameMatches: {
        for (final hit in hits)
          if (hit.matchedNickname case final nickname?) hit.item.id: nickname,
      },
    );
  }

  @override
  Future<void> close() async {
    await stop();
    return super.close();
  }
}

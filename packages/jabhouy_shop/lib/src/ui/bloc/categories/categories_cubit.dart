import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/src/data/item_repository.dart';
import 'package:jabhouy_shop/src/models/item.dart';

/// The Categories & units screen: every category, hidden ones included,
/// in the Shop's order. Owner and editor change them; a viewer only reads.
class CategoriesCubit extends Cubit<List<ItemCategory>?> {
  CategoriesCubit(this._repository, ShopScope scope)
    : canEdit = scope.role != MemberRole.viewer,
      super(null);

  final ItemRepository _repository;
  final bool canEdit;
  StreamSubscription<List<ItemCategory>>? _subscription;

  void load() {
    _subscription ??= _repository.watchCategories().listen(emit);
  }

  /// Moves the category at [from] to [to], its index once moved.
  Future<void> move(int from, int to) async {
    final categories = state;
    if (!canEdit || categories == null) return;
    final next = [...categories];
    next.insert(to, next.removeAt(from));
    emit(next);
    await _repository.reorderCategories([for (final c in next) c.id]);
  }

  Future<void> save(ItemCategory category) async {
    if (canEdit) await _repository.saveCategory(category);
  }

  Future<void> create(String name) => save(
    ItemCategory(id: newId(), name: name, sortOrder: state?.length ?? 0),
  );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

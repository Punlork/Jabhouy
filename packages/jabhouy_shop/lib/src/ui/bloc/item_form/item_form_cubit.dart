import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/src/data/item_repository.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/models/item_draft.dart';

part 'item_form_state.dart';
part 'item_form_cubit.g.dart';

/// The add/edit item form: what it shows, and saving it through
/// [ItemRepository]. The typed text lives in the page; it arrives here as
/// an [ItemDraft] on save.
class ItemFormCubit extends Cubit<ItemFormState> {
  ItemFormCubit(this._repository, {this.existing})
    : super(ItemFormState(categoryId: existing?.categoryId));

  final ItemRepository _repository;

  /// The Item being edited; null when adding.
  final Item? existing;

  /// Set once the user picks a category, so the name stops suggesting one.
  bool _categoryPicked = false;
  String? _warnedName;

  Future<void> load() async {
    final categories = await _repository.watchCategories().first;
    final settings = await _repository.priceSettings();
    final categoryId = existing != null
        ? existing!.categoryId
        : await _repository.lastUsedCategoryId();
    _categoryPicked = existing != null;
    emit(
      state.copyWith(
        status: ItemFormStatus.ready,
        categories: categories,
        settings: settings,
        categoryId: categoryId,
        units: await _unitsFor(categoryId),
      ),
    );
  }

  Future<void> pickCategory(String? id) async {
    _categoryPicked = true;
    emit(
      state.copyWith(
        categoryId: id,
        suggested: false,
        units: await _unitsFor(id),
      ),
    );
  }

  /// Saves a category typed in the picker and chooses it.
  Future<void> createCategory(String name) async {
    final category = ItemCategory(
      id: newId(),
      name: name.trim(),
      sortOrder: state.categories.length,
    );
    await _repository.saveCategory(category);
    emit(state.copyWith(categories: [...state.categories, category]));
    await pickCategory(category.id);
  }

  /// Suggests a category from the name until the user picks one.
  Future<void> nameChanged(String name) async {
    if (state.duplicateOf != null) {
      // Generated copyWith: null clears the warning; leaving it out keeps it.
      // ignore: avoid_redundant_argument_values
      emit(state.copyWith(duplicateOf: null));
    }
    if (_categoryPicked) return;
    final id = suggestCategory(name, state.categories);
    if (id == null || id == state.categoryId) return;
    emit(
      state.copyWith(
        categoryId: id,
        suggested: true,
        units: await _unitsFor(id),
      ),
    );
  }

  Future<void> save(ItemDraft draft) async {
    final barcodes = [
      for (final row in draft.rows)
        if (row.barcode case final code?) code,
    ];
    final owners = barcodes.isEmpty
        ? const <String, String>{}
        : await _repository.barcodeOwners(barcodes, exceptItemId: draft.id);
    final problems = draft.validate(barcodeOwners: owners);
    if (problems.isNotEmpty) {
      emit(state.copyWith(problems: problems));
      return;
    }

    // A duplicate name warns once; saving the same name again goes ahead.
    final name = draft.name.trim();
    if (name != _warnedName) {
      final other = await _repository.itemNamed(name, exceptItemId: draft.id);
      if (other != null) {
        _warnedName = name;
        emit(state.copyWith(problems: const {}, duplicateOf: other));
        return;
      }
    }

    emit(state.copyWith(status: ItemFormStatus.saving, problems: const {}));
    await _repository.saveItem(draft.toItem());
    emit(state.copyWith(status: ItemFormStatus.saved));
  }

  Future<List<String>> _unitsFor(String? categoryId) async =>
      categoryId == null ? const [] : _repository.unitsFor(categoryId);
}

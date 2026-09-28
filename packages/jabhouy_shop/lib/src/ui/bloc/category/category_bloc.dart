import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

part 'category_event.dart';
part 'category_state.dart';
part 'category_bloc.g.dart';

extension CategoryStateExtension on CategoryState {
  CategoryLoaded? get asLoaded => this is CategoryLoaded ? this as CategoryLoaded : null;
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc(
    this._repository, {
    FeatureFlags flags = const FixedFeatureFlags({}),
  })  : _inBackground = flags.isEnabled(Feature.backgroundSync),
        super(const CategoryInitial()) {
    _categorySubscription = _repository.watchCategories().listen((items) {
      add(_CategoryUpdatedFromLocal(items));
    });

    on<_CategoryUpdatedFromLocal>((event, emit) {
      emit(CategoryLoaded(items: event.items));
    });

    on<CategoryGetEvent>(_onGetItems);
    on<CategoryCreateEvent>(_onCreateItem);
    on<CategoryEditEvent>(_onEditItem);
    on<CategoryDeleteEvent>(_onDeleteItem);
  }

  /// Saves return at once and sync in the background: no overlay, and
  /// no claim about the server in the message.
  final bool _inBackground;
  final CategoryRepository _repository;
  late StreamSubscription<List<CategoryItemModel>> _categorySubscription;

  @override
  Future<void> close() {
    _categorySubscription.cancel();
    return super.close();
  }

  Future<void> _onCreateItem(CategoryCreateEvent event, Emitter<CategoryState> emit) async {
    if (!_inBackground) LoadingOverlay.show();
    try {
      (await _repository.createCategory(event.body)).fold(
        ok: (c) => showSuccessSnackBar(
          null,
          syncFeedback(c.syncStatus, done: 'Created: ${c.name}', inBackground: _inBackground),
        ),
        err: (e) => showErrorSnackBar(null, 'Failed to create item: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create item: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onEditItem(CategoryEditEvent event, Emitter<CategoryState> emit) async {
    if (!_inBackground) LoadingOverlay.show();
    try {
      (await _repository.updateCategory(event.body)).fold(
        ok: (c) => showSuccessSnackBar(
          null,
          syncFeedback(c.syncStatus, done: 'Updated: ${c.name}', inBackground: _inBackground),
        ),
        err: (e) => showErrorSnackBar(null, 'Failed to update item: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update item: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteItem(CategoryDeleteEvent event, Emitter<CategoryState> emit) async {
    if (!_inBackground) LoadingOverlay.show();
    try {
      (await _repository.deleteCategory(event.body)).fold(
        ok: (_) => showSuccessSnackBar(null, 'Deleted ${event.body.name}'),
        err: (e) => showErrorSnackBar(null, 'Failed to delete item: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete item: $e');
    } finally {
      if (!_inBackground) LoadingOverlay.hide();
    }
  }

  Future<void> _onGetItems(CategoryGetEvent event, Emitter<CategoryState> emit) async {
    if (state is! CategoryLoaded) {
      emit(const CategoryLoading());
    }
    try {
      await _repository.refreshCategories();
    } catch (e) {
      if (state is! CategoryLoaded) {
        // emit(CategoryError('Failed to load items: $e'));
      }
    }
  }
}

class _CategoryUpdatedFromLocal extends CategoryEvent {
  _CategoryUpdatedFromLocal(this.items);
  final List<CategoryItemModel> items;

  @override
  List<Object?> get props => [items];
}

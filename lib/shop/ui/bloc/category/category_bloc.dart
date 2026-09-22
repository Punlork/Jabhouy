import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

part 'category_event.dart';
part 'category_state.dart';

extension CategoryStateExtension on CategoryState {
  CategoryLoaded? get asLoaded => this is CategoryLoaded ? this as CategoryLoaded : null;
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc(this._repository) : super(const CategoryInitial()) {
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

  final CategoryRepository _repository;
  late StreamSubscription<List<CategoryItemModel>> _categorySubscription;

  @override
  Future<void> close() {
    _categorySubscription.cancel();
    return super.close();
  }

  Future<void> _onCreateItem(CategoryCreateEvent event, Emitter<CategoryState> emit) async {
    LoadingOverlay.show();
    try {
      (await _repository.createCategory(event.body)).fold(
        ok: (c) => showSuccessSnackBar(
          null,
          syncFeedback(c.syncStatus, done: 'Created: ${c.name}'),
        ),
        err: (e) => showErrorSnackBar(null, 'Failed to create item: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onEditItem(CategoryEditEvent event, Emitter<CategoryState> emit) async {
    LoadingOverlay.show();
    try {
      (await _repository.updateCategory(event.body)).fold(
        ok: (c) => showSuccessSnackBar(
          null,
          syncFeedback(c.syncStatus, done: 'Updated: ${c.name}'),
        ),
        err: (e) => showErrorSnackBar(null, 'Failed to update item: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteItem(CategoryDeleteEvent event, Emitter<CategoryState> emit) async {
    LoadingOverlay.show();
    try {
      (await _repository.deleteCategory(event.body)).fold(
        ok: (_) => showSuccessSnackBar(null, 'Deleted ${event.body.name}'),
        err: (e) => showErrorSnackBar(null, 'Failed to delete item: ${e.message}'),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete item: $e');
    } finally {
      LoadingOverlay.hide();
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

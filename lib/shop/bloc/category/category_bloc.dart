import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

part 'category_event.dart';
part 'category_state.dart';

extension CategoryStateExtension on CategoryState {
  CategoryLoaded? get asLoaded => this is CategoryLoaded ? this as CategoryLoaded : null;
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc(this._service) : super(const CategoryInitial()) {
    _categorySubscription = _service.watchCategories().listen((items) {
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

  final CategoryService _service;
  late StreamSubscription<List<CategoryItemModel>> _categorySubscription;

  @override
  Future<void> close() {
    _categorySubscription.cancel();
    return super.close();
  }

  Future<void> _onCreateItem(CategoryCreateEvent event, Emitter<CategoryState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.createCategory(event.body);
      if (!response.success) return;
      showSuccessSnackBar(null, 'Created: ${response.data?.name}');
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onEditItem(CategoryEditEvent event, Emitter<CategoryState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.updateCategory(event.body);
      if (!response.success) return;
      showSuccessSnackBar(null, 'Updated: ${response.data?.name}');
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteItem(CategoryDeleteEvent event, Emitter<CategoryState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.deleteCategory(event.body);
      if (!response.success) return;
      showSuccessSnackBar(null, 'Deleted ${event.body.name}');
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
      await _service.getCategory();
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

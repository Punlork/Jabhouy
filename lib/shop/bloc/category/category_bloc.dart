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
    on<CategoryGetEvent>(_onGetItems);
    on<CategoryCreateEvent>(_onCreateItem);
    on<CategoryEditEvent>(_onEditItem);
    on<CategoryDeleteEvent>(_onDeleteItem);
  }

  final CategoryService _service;

  Future<void> _onCreateItem(CategoryCreateEvent event, Emitter<CategoryState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.createCategory(event.body);
      if (!response.success) return;

      showSuccessSnackBar(null, 'Created: ${response.data?.name}');

      final updatedItems = [response.data!, ...?state.asLoaded?.items];

      emit(CategoryLoaded(items: updatedItems));
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

      final currentItems = state.asLoaded?.items ?? <CategoryItemModel>[];
      final updatedItems = currentItems
          .map(
            (item) => item.id == event.body.id ? response.data! : item,
          )
          .toList();

      emit(CategoryLoaded(items: updatedItems));
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

      final updatedItems = List<CategoryItemModel>.from(state.asLoaded?.items ?? [])
        ..removeWhere(
          (item) => item.id == event.body.id,
        );

      emit(CategoryLoaded(items: updatedItems));
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onGetItems(CategoryGetEvent event, Emitter<CategoryState> emit) async {
    emit(const CategoryLoading());
    try {
      final response = await _service.getCategory();

      if (response.success && response.data != null) {
        emit(CategoryLoaded(items: response.data!));
      }
    } catch (e) {
      emit(CategoryError('Failed to load items: $e'));
    }
  }
}

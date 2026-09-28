part of 'category_bloc.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

@CopyWith()
class CategoryLoaded extends CategoryState {
  const CategoryLoaded({
    required this.items,
  });

  final List<CategoryItemModel> items;

  @override
  List<Object?> get props => [
        items.length,
        ...items,
      ];
}

class CategoryError extends CategoryState {
  const CategoryError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

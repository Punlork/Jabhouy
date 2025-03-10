part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {}

class CategoryGetEvent extends CategoryEvent {
  @override
  List<Object?> get props => throw UnimplementedError();
}

class CategoryCreateEvent extends CategoryEvent {
  CategoryCreateEvent({
    required this.body,
  });

  final CategoryItemModel body;

  @override
  List<Object?> get props => [body];
}

class CategoryEditEvent extends CategoryEvent {
  CategoryEditEvent({required this.body});

  final CategoryItemModel body;

  @override
  List<Object?> get props => [body];
}

class CategoryDeleteEvent extends CategoryEvent {
  CategoryDeleteEvent({required this.body});

  final CategoryItemModel body;
  @override
  List<Object?> get props => [body];
}

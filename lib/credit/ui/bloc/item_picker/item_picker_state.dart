part of 'item_picker_cubit.dart';

@CopyWith()
class ItemPickerState extends Equatable {
  const ItemPickerState({
    this.loading = true,
    this.items = const [],
    this.categories = const [],
    this.categoryId,
    this.query = '',
    this.quantities = const {},
    this.lines = const [],
  });

  final bool loading;

  /// Narrowed by [categoryId] and [query].
  final List<Item> items;
  final List<ItemCategory> categories;
  final String? categoryId;
  final String query;

  /// Price option id → how many; only options above 0.
  final Map<String, int> quantities;

  /// What picking now would add, one line per chosen Price option.
  final List<CreditLine> lines;

  @override
  List<Object?> get props => [
    loading,
    items,
    categories,
    categoryId,
    query,
    quantities,
    [for (final l in lines) (l.id, l.priceId, l.qty)],
  ];
}

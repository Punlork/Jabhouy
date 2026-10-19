part of 'item_form_cubit.dart';

enum ItemFormStatus { loading, ready, saving, saved }

@CopyWith()
class ItemFormState extends Equatable {
  const ItemFormState({
    this.status = ItemFormStatus.loading,
    this.categories = const [],
    this.settings = const PriceSettings(),
    this.categoryId,
    this.suggested = false,
    this.units = const [],
    this.problems = const {},
    this.duplicateOf,
  });

  final ItemFormStatus status;
  final List<ItemCategory> categories;
  final PriceSettings settings;
  final String? categoryId;

  /// True when [categoryId] was suggested from the name.
  final bool suggested;

  /// Unit chips for [categoryId], most used first.
  final List<String> units;

  /// Keyed as in [ItemDraft.validate].
  final Map<String, FormProblem> problems;

  /// Id of another Item with the same name, shown as a warning.
  final String? duplicateOf;

  @override
  List<Object?> get props => [
    status,
    categories,
    settings,
    categoryId,
    suggested,
    units,
    problems,
    duplicateOf,
  ];
}

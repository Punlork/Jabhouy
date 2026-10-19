// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_form_cubit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ItemFormStateCWProxy {
  ItemFormState status(ItemFormStatus status);

  ItemFormState categories(List<ItemCategory> categories);

  ItemFormState settings(PriceSettings settings);

  ItemFormState categoryId(String? categoryId);

  ItemFormState suggested(bool suggested);

  ItemFormState units(List<String> units);

  ItemFormState problems(Map<String, FormProblem> problems);

  ItemFormState duplicateOf(String? duplicateOf);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ItemFormState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ItemFormState(...).copyWith(id: 12, name: "My name")
  /// ```
  ItemFormState call({
    ItemFormStatus status,
    List<ItemCategory> categories,
    PriceSettings settings,
    String? categoryId,
    bool suggested,
    List<String> units,
    Map<String, FormProblem> problems,
    String? duplicateOf,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfItemFormState.copyWith(...)` or call `instanceOfItemFormState.copyWith.fieldName(value)` for a single field.
class _$ItemFormStateCWProxyImpl implements _$ItemFormStateCWProxy {
  const _$ItemFormStateCWProxyImpl(this._value);

  final ItemFormState _value;

  @override
  ItemFormState status(ItemFormStatus status) => call(status: status);

  @override
  ItemFormState categories(List<ItemCategory> categories) =>
      call(categories: categories);

  @override
  ItemFormState settings(PriceSettings settings) => call(settings: settings);

  @override
  ItemFormState categoryId(String? categoryId) => call(categoryId: categoryId);

  @override
  ItemFormState suggested(bool suggested) => call(suggested: suggested);

  @override
  ItemFormState units(List<String> units) => call(units: units);

  @override
  ItemFormState problems(Map<String, FormProblem> problems) =>
      call(problems: problems);

  @override
  ItemFormState duplicateOf(String? duplicateOf) =>
      call(duplicateOf: duplicateOf);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ItemFormState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ItemFormState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ItemFormState call({
    Object? status = const $CopyWithPlaceholder(),
    Object? categories = const $CopyWithPlaceholder(),
    Object? settings = const $CopyWithPlaceholder(),
    Object? categoryId = const $CopyWithPlaceholder(),
    Object? suggested = const $CopyWithPlaceholder(),
    Object? units = const $CopyWithPlaceholder(),
    Object? problems = const $CopyWithPlaceholder(),
    Object? duplicateOf = const $CopyWithPlaceholder(),
  }) {
    return ItemFormState(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ItemFormStatus,
      categories:
          categories == const $CopyWithPlaceholder() || categories == null
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<ItemCategory>,
      settings: settings == const $CopyWithPlaceholder() || settings == null
          ? _value.settings
          // ignore: cast_nullable_to_non_nullable
          : settings as PriceSettings,
      categoryId: categoryId == const $CopyWithPlaceholder()
          ? _value.categoryId
          // ignore: cast_nullable_to_non_nullable
          : categoryId as String?,
      suggested: suggested == const $CopyWithPlaceholder() || suggested == null
          ? _value.suggested
          // ignore: cast_nullable_to_non_nullable
          : suggested as bool,
      units: units == const $CopyWithPlaceholder() || units == null
          ? _value.units
          // ignore: cast_nullable_to_non_nullable
          : units as List<String>,
      problems: problems == const $CopyWithPlaceholder() || problems == null
          ? _value.problems
          // ignore: cast_nullable_to_non_nullable
          : problems as Map<String, FormProblem>,
      duplicateOf: duplicateOf == const $CopyWithPlaceholder()
          ? _value.duplicateOf
          // ignore: cast_nullable_to_non_nullable
          : duplicateOf as String?,
    );
  }
}

extension $ItemFormStateCopyWith on ItemFormState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfItemFormState.copyWith(...)` or `instanceOfItemFormState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ItemFormStateCWProxy get copyWith => _$ItemFormStateCWProxyImpl(this);
}

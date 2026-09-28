// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaginationCWProxy {
  Pagination total(int? total);

  Pagination page(int page);

  Pagination limit(int limit);

  Pagination totalPage(int? totalPage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Pagination(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Pagination(...).copyWith(id: 12, name: "My name")
  /// ```
  Pagination call({int? total, int page, int limit, int? totalPage});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPagination.copyWith(...)` or call `instanceOfPagination.copyWith.fieldName(value)` for a single field.
class _$PaginationCWProxyImpl implements _$PaginationCWProxy {
  const _$PaginationCWProxyImpl(this._value);

  final Pagination _value;

  @override
  Pagination total(int? total) => call(total: total);

  @override
  Pagination page(int page) => call(page: page);

  @override
  Pagination limit(int limit) => call(limit: limit);

  @override
  Pagination totalPage(int? totalPage) => call(totalPage: totalPage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Pagination(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Pagination(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Pagination call({
    Object? total = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
    Object? limit = const $CopyWithPlaceholder(),
    Object? totalPage = const $CopyWithPlaceholder(),
  }) {
    return Pagination(
      total: total == const $CopyWithPlaceholder()
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int?,
      page: page == const $CopyWithPlaceholder() || page == null
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as int,
      limit: limit == const $CopyWithPlaceholder() || limit == null
          ? _value.limit
          // ignore: cast_nullable_to_non_nullable
          : limit as int,
      totalPage: totalPage == const $CopyWithPlaceholder()
          ? _value.totalPage
          // ignore: cast_nullable_to_non_nullable
          : totalPage as int?,
    );
  }
}

extension $PaginationCopyWith on Pagination {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPagination.copyWith(...)` or `instanceOfPagination.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaginationCWProxy get copyWith => _$PaginationCWProxyImpl(this);
}

abstract class _$PaginatedResponseCWProxy<T> {
  PaginatedResponse<T> items(List<T> items);

  PaginatedResponse<T> pagination(Pagination pagination);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaginatedResponse<T>(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaginatedResponse<T>(...).copyWith(id: 12, name: "My name")
  /// ```
  PaginatedResponse<T> call({List<T> items, Pagination pagination});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPaginatedResponse.copyWith(...)` or call `instanceOfPaginatedResponse.copyWith.fieldName(value)` for a single field.
class _$PaginatedResponseCWProxyImpl<T>
    implements _$PaginatedResponseCWProxy<T> {
  const _$PaginatedResponseCWProxyImpl(this._value);

  final PaginatedResponse<T> _value;

  @override
  PaginatedResponse<T> items(List<T> items) => call(items: items);

  @override
  PaginatedResponse<T> pagination(Pagination pagination) =>
      call(pagination: pagination);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaginatedResponse<T>(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaginatedResponse<T>(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PaginatedResponse<T> call({
    Object? items = const $CopyWithPlaceholder(),
    Object? pagination = const $CopyWithPlaceholder(),
  }) {
    return PaginatedResponse<T>(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<T>,
      pagination:
          pagination == const $CopyWithPlaceholder() || pagination == null
          ? _value.pagination
          // ignore: cast_nullable_to_non_nullable
          : pagination as Pagination,
    );
  }
}

extension $PaginatedResponseCopyWith<T> on PaginatedResponse<T> {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPaginatedResponse.copyWith(...)` or `instanceOfPaginatedResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaginatedResponseCWProxy<T> get copyWith =>
      _$PaginatedResponseCWProxyImpl<T>(this);
}

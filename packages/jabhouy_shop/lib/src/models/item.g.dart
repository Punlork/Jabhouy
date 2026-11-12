// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PriceSettingsCWProxy {
  PriceSettings useWholesale(bool useWholesale);

  PriceSettings useCost(bool useCost);

  PriceSettings currency(Currency currency);

  PriceSettings khrPerUsd(int khrPerUsd);

  PriceSettings showConverted(bool showConverted);

  PriceSettings rateUpdatedAt(DateTime? rateUpdatedAt);

  PriceSettings rateUpdatedBy(String? rateUpdatedBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  PriceSettings call({
    bool useWholesale,
    bool useCost,
    Currency currency,
    int khrPerUsd,
    bool showConverted,
    DateTime? rateUpdatedAt,
    String? rateUpdatedBy,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPriceSettings.copyWith(...)` or call `instanceOfPriceSettings.copyWith.fieldName(value)` for a single field.
class _$PriceSettingsCWProxyImpl implements _$PriceSettingsCWProxy {
  const _$PriceSettingsCWProxyImpl(this._value);

  final PriceSettings _value;

  @override
  PriceSettings useWholesale(bool useWholesale) =>
      call(useWholesale: useWholesale);

  @override
  PriceSettings useCost(bool useCost) => call(useCost: useCost);

  @override
  PriceSettings currency(Currency currency) => call(currency: currency);

  @override
  PriceSettings khrPerUsd(int khrPerUsd) => call(khrPerUsd: khrPerUsd);

  @override
  PriceSettings showConverted(bool showConverted) =>
      call(showConverted: showConverted);

  @override
  PriceSettings rateUpdatedAt(DateTime? rateUpdatedAt) =>
      call(rateUpdatedAt: rateUpdatedAt);

  @override
  PriceSettings rateUpdatedBy(String? rateUpdatedBy) =>
      call(rateUpdatedBy: rateUpdatedBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PriceSettings call({
    Object? useWholesale = const $CopyWithPlaceholder(),
    Object? useCost = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
    Object? khrPerUsd = const $CopyWithPlaceholder(),
    Object? showConverted = const $CopyWithPlaceholder(),
    Object? rateUpdatedAt = const $CopyWithPlaceholder(),
    Object? rateUpdatedBy = const $CopyWithPlaceholder(),
  }) {
    return PriceSettings(
      useWholesale:
          useWholesale == const $CopyWithPlaceholder() || useWholesale == null
          ? _value.useWholesale
          // ignore: cast_nullable_to_non_nullable
          : useWholesale as bool,
      useCost: useCost == const $CopyWithPlaceholder() || useCost == null
          ? _value.useCost
          // ignore: cast_nullable_to_non_nullable
          : useCost as bool,
      currency: currency == const $CopyWithPlaceholder() || currency == null
          ? _value.currency
          // ignore: cast_nullable_to_non_nullable
          : currency as Currency,
      khrPerUsd: khrPerUsd == const $CopyWithPlaceholder() || khrPerUsd == null
          ? _value.khrPerUsd
          // ignore: cast_nullable_to_non_nullable
          : khrPerUsd as int,
      showConverted:
          showConverted == const $CopyWithPlaceholder() || showConverted == null
          ? _value.showConverted
          // ignore: cast_nullable_to_non_nullable
          : showConverted as bool,
      rateUpdatedAt: rateUpdatedAt == const $CopyWithPlaceholder()
          ? _value.rateUpdatedAt
          // ignore: cast_nullable_to_non_nullable
          : rateUpdatedAt as DateTime?,
      rateUpdatedBy: rateUpdatedBy == const $CopyWithPlaceholder()
          ? _value.rateUpdatedBy
          // ignore: cast_nullable_to_non_nullable
          : rateUpdatedBy as String?,
    );
  }
}

extension $PriceSettingsCopyWith on PriceSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPriceSettings.copyWith(...)` or `instanceOfPriceSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PriceSettingsCWProxy get copyWith => _$PriceSettingsCWProxyImpl(this);
}

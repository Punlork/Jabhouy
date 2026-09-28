// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_bloc.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppStateCWProxy {
  AppState locale(Locale locale);

  AppState isGridView(bool isGridView);

  AppState isDarkMode(bool isDarkMode);

  AppState isAppLogCaptureEnabled(bool isAppLogCaptureEnabled);

  AppState isNetworkLogCaptureEnabled(bool isNetworkLogCaptureEnabled);

  AppState deviceRole(DeviceRole deviceRole);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppState(...).copyWith(id: 12, name: "My name")
  /// ```
  AppState call({
    Locale locale,
    bool isGridView,
    bool isDarkMode,
    bool isAppLogCaptureEnabled,
    bool isNetworkLogCaptureEnabled,
    DeviceRole deviceRole,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppState.copyWith(...)` or call `instanceOfAppState.copyWith.fieldName(value)` for a single field.
class _$AppStateCWProxyImpl implements _$AppStateCWProxy {
  const _$AppStateCWProxyImpl(this._value);

  final AppState _value;

  @override
  AppState locale(Locale locale) => call(locale: locale);

  @override
  AppState isGridView(bool isGridView) => call(isGridView: isGridView);

  @override
  AppState isDarkMode(bool isDarkMode) => call(isDarkMode: isDarkMode);

  @override
  AppState isAppLogCaptureEnabled(bool isAppLogCaptureEnabled) =>
      call(isAppLogCaptureEnabled: isAppLogCaptureEnabled);

  @override
  AppState isNetworkLogCaptureEnabled(bool isNetworkLogCaptureEnabled) =>
      call(isNetworkLogCaptureEnabled: isNetworkLogCaptureEnabled);

  @override
  AppState deviceRole(DeviceRole deviceRole) => call(deviceRole: deviceRole);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppState call({
    Object? locale = const $CopyWithPlaceholder(),
    Object? isGridView = const $CopyWithPlaceholder(),
    Object? isDarkMode = const $CopyWithPlaceholder(),
    Object? isAppLogCaptureEnabled = const $CopyWithPlaceholder(),
    Object? isNetworkLogCaptureEnabled = const $CopyWithPlaceholder(),
    Object? deviceRole = const $CopyWithPlaceholder(),
  }) {
    return AppState(
      locale: locale == const $CopyWithPlaceholder() || locale == null
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as Locale,
      isGridView:
          isGridView == const $CopyWithPlaceholder() || isGridView == null
          ? _value.isGridView
          // ignore: cast_nullable_to_non_nullable
          : isGridView as bool,
      isDarkMode:
          isDarkMode == const $CopyWithPlaceholder() || isDarkMode == null
          ? _value.isDarkMode
          // ignore: cast_nullable_to_non_nullable
          : isDarkMode as bool,
      isAppLogCaptureEnabled:
          isAppLogCaptureEnabled == const $CopyWithPlaceholder() ||
              isAppLogCaptureEnabled == null
          ? _value.isAppLogCaptureEnabled
          // ignore: cast_nullable_to_non_nullable
          : isAppLogCaptureEnabled as bool,
      isNetworkLogCaptureEnabled:
          isNetworkLogCaptureEnabled == const $CopyWithPlaceholder() ||
              isNetworkLogCaptureEnabled == null
          ? _value.isNetworkLogCaptureEnabled
          // ignore: cast_nullable_to_non_nullable
          : isNetworkLogCaptureEnabled as bool,
      deviceRole:
          deviceRole == const $CopyWithPlaceholder() || deviceRole == null
          ? _value.deviceRole
          // ignore: cast_nullable_to_non_nullable
          : deviceRole as DeviceRole,
    );
  }
}

extension $AppStateCopyWith on AppState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppState.copyWith(...)` or `instanceOfAppState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppStateCWProxy get copyWith => _$AppStateCWProxyImpl(this);
}

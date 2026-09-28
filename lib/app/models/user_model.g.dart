// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserCWProxy {
  User id(String? id);

  User email(String? email);

  User name(String? name);

  User emailVerified(bool? emailVerified);

  User image(String? image);

  User username(String? username);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `User(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// User(...).copyWith(id: 12, name: "My name")
  /// ```
  User call({
    String? id,
    String? email,
    String? name,
    bool? emailVerified,
    String? image,
    String? username,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUser.copyWith(...)` or call `instanceOfUser.copyWith.fieldName(value)` for a single field.
class _$UserCWProxyImpl implements _$UserCWProxy {
  const _$UserCWProxyImpl(this._value);

  final User _value;

  @override
  User id(String? id) => call(id: id);

  @override
  User email(String? email) => call(email: email);

  @override
  User name(String? name) => call(name: name);

  @override
  User emailVerified(bool? emailVerified) => call(emailVerified: emailVerified);

  @override
  User image(String? image) => call(image: image);

  @override
  User username(String? username) => call(username: username);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `User(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// User(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  User call({
    Object? id = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? emailVerified = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
  }) {
    return User(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String?,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      emailVerified: emailVerified == const $CopyWithPlaceholder()
          ? _value.emailVerified
          // ignore: cast_nullable_to_non_nullable
          : emailVerified as bool?,
      image: image == const $CopyWithPlaceholder()
          ? _value.image
          // ignore: cast_nullable_to_non_nullable
          : image as String?,
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String?,
    );
  }
}

extension $UserCopyWith on User {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUser.copyWith(...)` or `instanceOfUser.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UserCWProxy get copyWith => _$UserCWProxyImpl(this);
}

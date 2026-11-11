import 'package:jabhouy/membership/data/me_api.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// A failed call that carries the API's `{ code }` becomes a
/// [ShopApiException], so callers match on `code` (`invite_used`,
/// `not_member`, …) and the sync engine sees the errors it acts on.
extension ShopApiError on ApiResponse<dynamic> {
  ShopApiException? get shopError => switch (code) {
    final code? when !success => ShopApiException(
      code,
      statusCode ?? 0,
      message,
    ),
    _ => null,
  };

  Result<void> toShopVoidResult() => switch (shopError) {
    final error? => Err(error),
    null => toVoidResult(),
  };
}

/// A one-time code for one person to join the Shop with [role].
class ShopInvite {
  const ShopInvite({
    required this.code,
    required this.role,
    required this.expiresAt,
  });

  factory ShopInvite.fromJson(Map<String, dynamic> json) => ShopInvite(
    code: json['code'] as String,
    role: MemberRole.parse(json['role'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
  );

  final String code;
  final MemberRole role;
  final DateTime expiresAt;
}

/// Someone in the Shop, for the owner's Members screen.
class ShopMember {
  const ShopMember({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  factory ShopMember.fromJson(Map<String, dynamic> json) => ShopMember(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String? ?? '',
    role: MemberRole.parse(json['role'] as String),
  );

  final String userId;
  final String displayName;
  final MemberRole role;
}

/// Invites, joining and managing Members (jabhouy-api members spec).
/// Owner-only calls answer `forbidden_role` for anyone else.
class MembershipApi {
  MembershipApi(this._api);

  final ApiService _api;

  Future<Result<ShopInvite>> createInvite(String shopId, MemberRole role) =>
      _value(
        _api.post<ShopInvite>(
          '/shops/$shopId/invites',
          body: {'role': role.name},
          showSnackBar: false,
          parser: (v) => ShopInvite.fromJson(v as Map<String, dynamic>),
        ),
      );

  /// Joins with [code]. Fails with a [ShopApiException] whose code is
  /// `invite_not_found`, `invite_expired`, `invite_used` or `already_member`.
  Future<Result<ShopMembership>> accept(String code) => _value(
    _api.post<ShopMembership>(
      '/invites/${Uri.encodeComponent(code)}/accept',
      showSnackBar: false,
      parser: (v) => ShopMembership.fromJson(
        (v as Map<String, dynamic>)['shop'] as Map<String, dynamic>,
      ),
    ),
  );

  Future<Result<List<ShopMember>>> members(String shopId) => _value(
    _api.get<List<ShopMember>>(
      '/shops/$shopId/members',
      showSnackBar: false,
      parser: (v) => [
        for (final m in v as List)
          ShopMember.fromJson(m as Map<String, dynamic>),
      ],
    ),
  );

  /// `owner` hands the Shop over; the caller becomes an editor.
  Future<Result<void>> setRole(
    String shopId,
    String userId,
    MemberRole role,
  ) async => (await _api.put<dynamic>(
    '/shops/$shopId/members/$userId',
    body: {'role': role.name},
    showSnackBar: false,
  )).toShopVoidResult();

  Future<Result<void>> remove(String shopId, String userId) async =>
      (await _api.delete<dynamic>(
        '/shops/$shopId/members/$userId',
        showSnackBar: false,
      )).toShopVoidResult();

  static Future<Result<T>> _value<T extends Object>(
    Future<ApiResponse<T>> call,
  ) async {
    final response = await call;
    return switch (response.shopError) {
      final error? => Err(error),
      null => response.toResult(),
    };
  }
}

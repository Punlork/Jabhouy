import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';

/// One Shop the signed-in user belongs to.
class ShopMembership {
  const ShopMembership({
    required this.id,
    required this.name,
    required this.role,
  });

  factory ShopMembership.fromJson(Map<String, dynamic> json) => ShopMembership(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        role: MemberRole.parse(json['role'] as String? ?? ''),
      );

  final String id;
  final String name;
  final MemberRole role;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'role': role.name};
}

/// `GET /me`: the Shops the signed-in user belongs to.
// ignore: one_member_abstracts — the fake and the real API swap behind it.
abstract interface class MeApi {
  Future<Result<List<ShopMembership>>> shops(String userId);
}

/// Stands in for `GET /me` until the API has Shops: one Shop per user,
/// with a fixed id so data stays put across launches.
class FakeMeApi implements MeApi {
  const FakeMeApi();

  @override
  Future<Result<List<ShopMembership>>> shops(String userId) async => Ok([
        ShopMembership(
          id: 'local-$userId',
          name: '',
          role: MemberRole.owner,
        ),
      ]);
}

/// The fake until FEATURE_SERVER_SHOPS is on in the flavor's config.
MeApi meApiFor(FeatureFlags flags, ApiService apiService) =>
    flags.isEnabled(Feature.serverShops)
        ? HttpMeApi(apiService)
        : const FakeMeApi();

/// The real `GET /me` (jabhouy-api #2).
class HttpMeApi extends BaseService implements MeApi {
  HttpMeApi(super.apiService);

  @override
  String get basePath => '/me';

  @override
  Future<Result<List<ShopMembership>>> shops(String userId) async {
    final response = await get<List<ShopMembership>>(
      '',
      showSnackBar: false,
      parser: (value) => [
        for (final shop in (value as Map<String, dynamic>)['shops'] as List)
          ShopMembership.fromJson(shop as Map<String, dynamic>),
      ],
    );
    return response.toResult();
  }
}

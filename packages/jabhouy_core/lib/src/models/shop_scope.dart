import 'package:jabhouy_core/src/models/member_role.dart';

/// The Shop this phone works in, as feature packages see it. The app's
/// `CurrentShop` implements it; packages cannot import the app.
abstract interface class ShopScope {
  String? get shopId;
  MemberRole? get role;
  String? get userId;

  /// False for the stand-in Shop used before the API has Shops: its rows
  /// stay on the phone, so no sync job is queued for them.
  bool get syncs;
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jabhouy/membership/data/me_api.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which Shop this phone is working in right now, and the user's role
/// there. Every query and save is scoped to [id]. Notifies when either
/// changes, so Home rebuilds its lists for the new Shop or role.
class CurrentShop extends ChangeNotifier implements ShopScope {
  CurrentShop(this._api);

  static const _key = 'current_shop';

  final MeApi _api;
  ShopMembership? _shop;
  String? _userId;
  List<ShopMembership> _shops = const [];

  /// Null until [load] has run once after sign-in.
  String? get id => _shop?.id;

  @override
  String? get shopId => id;

  @override
  MemberRole? get role => _shop?.role;

  @override
  String? get userId => _userId;

  @override
  bool get syncs => switch (_api) {
        FakeMeApi(:final syncs) => syncs,
        _ => true,
      };

  /// Every Shop the user belongs to, for the shop switcher.
  List<ShopMembership> get shops => _shops;

  /// Asks the server which Shops the user is in. Keeps the remembered
  /// Shop if the user is still in it, else picks the first. Offline, falls
  /// back to what was cached.
  Future<void> load(String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    final cached = _read(prefs);
    switch (await _api.shops(userId)) {
      case Ok(:final value) when value.isNotEmpty:
        _shops = value;
        // The remembered Shop if still in it; after a removal, the user's own.
        _shop = value.firstWhere(
          (s) => s.id == cached?.$1,
          orElse: () => value.firstWhere(
            (s) => s.role == MemberRole.owner,
            orElse: () => value.first,
          ),
        );
        await _write(prefs);
      case _:
        if (cached != null) {
          _shops = cached.$2;
          _shop = _shops.firstWhere((s) => s.id == cached.$1);
        }
    }
  }

  /// Asks the server again: after joining, a removal or a role change.
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;
    final before = (_shop?.id, _shop?.role, _shops.length);
    await load(userId);
    if ((_shop?.id, _shop?.role, _shops.length) != before) notifyListeners();
  }

  /// Works in [shopId] from now on; it must be one of [shops].
  Future<void> switchTo(String shopId) async {
    if (shopId == _shop?.id) return;
    _shop = _shops.firstWhere((s) => s.id == shopId);
    await _write(await SharedPreferences.getInstance());
    notifyListeners();
  }

  Future<void> clear() async {
    _shop = null;
    _userId = null;
    _shops = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  (String, List<ShopMembership>)? _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (
      json['id'] as String,
      [
        for (final s in json['shops'] as List)
          ShopMembership.fromJson(s as Map<String, dynamic>),
      ],
    );
  }

  Future<void> _write(SharedPreferences prefs) => prefs.setString(
        _key,
        jsonEncode({
          'id': _shop!.id,
          'shops': [for (final s in _shops) s.toJson()],
        }),
      );
}

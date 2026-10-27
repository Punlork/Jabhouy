import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/membership/membership.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

class _StubMeApi implements MeApi {
  _StubMeApi(this.answer);

  Result<List<ShopMembership>> answer;

  @override
  Future<Result<List<ShopMembership>>> shops(String userId) async => answer;
}

const _home = ShopMembership(id: 'a', name: 'ហាងខ្ញុំ', role: MemberRole.owner);
const _mum = ShopMembership(id: 'b', name: 'ហាងម្តាយ', role: MemberRole.viewer);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the fake gives one owned shop with a stable id', () async {
    final shop = CurrentShop(const FakeMeApi());
    await shop.load('u1');
    expect(shop.id, 'local-u1');
    expect(shop.role, MemberRole.owner);
  });

  test('first load picks the first shop and remembers it', () async {
    final api = _StubMeApi(const Ok([_home, _mum]));
    await CurrentShop(api).load('u1');

    final again = CurrentShop(_StubMeApi(const Ok([_mum, _home])));
    await again.load('u1');
    expect(again.id, 'a', reason: 'the remembered shop wins over order');
    expect(again.shops, hasLength(2));
  });

  test('a remembered shop the user left is dropped', () async {
    await CurrentShop(_StubMeApi(const Ok([_home, _mum]))).load('u1');
    final again = CurrentShop(_StubMeApi(const Ok([_mum])));
    await again.load('u1');
    expect(again.id, 'b');
    expect(again.role, MemberRole.viewer);
  });

  test('offline falls back to the cache', () async {
    await CurrentShop(_StubMeApi(const Ok([_home]))).load('u1');
    final offline = CurrentShop(
      _StubMeApi(const Err(AppException('offline'))),
    );
    await offline.load('u1');
    expect(offline.id, 'a');
    expect(offline.role, MemberRole.owner);
  });

  test('clear forgets the shop and its cache', () async {
    final shop = CurrentShop(_StubMeApi(const Ok([_home])));
    await shop.load('u1');
    await shop.clear();
    expect(shop.id, isNull);

    final offline = CurrentShop(
      _StubMeApi(const Err(AppException('offline'))),
    );
    await offline.load('u1');
    expect(offline.id, isNull);
  });

  test('FEATURE_SERVER_SHOPS picks the real API, otherwise the fake', () {
    final api = _MockApiService();
    expect(meApiFor(const FixedFeatureFlags({}), api), isA<FakeMeApi>());
    expect(
      meApiFor(const FixedFeatureFlags({Feature.serverShops}), api),
      isA<HttpMeApi>(),
    );
    final local = meApiFor(
      const FixedFeatureFlags({Feature.userScopedApi}),
      api,
    );
    expect(CurrentShop(local).syncs, isTrue);
    expect(
      CurrentShop(meApiFor(const FixedFeatureFlags({}), api)).syncs,
      isFalse,
    );
  });

  test('viewers cannot edit prices', () {
    expect(MemberRole.viewer.canEditPrices, isFalse);
    expect(MemberRole.editor.canEditPrices, isTrue);
    expect(MemberRole.parse('nonsense'), MemberRole.viewer);
  });
}

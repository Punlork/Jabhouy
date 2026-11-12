import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/membership/membership.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

void main() {
  test('a failure with an API code becomes a ShopApiException', () {
    final response = ApiResponse<dynamic>(
      success: false,
      message: 'Not a member of this shop',
      statusCode: 403,
      code: 'not_member',
    );
    final error = response.shopError;
    expect(error, isA<ShopApiException>());
    expect((error!.code, error.statusCode), ('not_member', 403));
    final result = response.toShopVoidResult();
    expect(result, isA<Err<void>>());
    expect(((result as Err<void>).error as ShopApiException).code, 'not_member');
  });

  test('a success, or a failure without a code, stays as it was', () {
    expect(ApiResponse<dynamic>(success: true, code: 'x').shopError, isNull);
    final plain = ApiResponse<dynamic>(success: false, statusCode: 500);
    expect(plain.shopError, isNull);
    expect(
      (plain.toShopVoidResult() as Err<void>).error,
      isNot(isA<ShopApiException>()),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/membership/membership.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

class _FakeMembershipApi extends Fake implements MembershipApi {
  _FakeMembershipApi(this.answer);

  Result<ShopMembership> answer;
  final codes = <String>[];

  @override
  Future<Result<ShopMembership>> accept(String code) async {
    codes.add(code);
    return answer;
  }
}

void main() {
  late _FakeMembershipApi api;

  setUp(() async {
    await getIt.reset();
    api = _FakeMembershipApi(
      const Err(ShopApiException('invite_expired', 410)),
    );
    getIt.registerSingleton<MembershipApi>(api);
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester, {String? code}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: JoinShopPage(code: code),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder join() => find.widgetWithText(FilledButton, 'ចូលរួម');

  testWidgets('a pasted code is cleaned, uppercased and fills the boxes', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(tester.widget<FilledButton>(join()).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'k7p-2q xz9');
    await tester.pump();

    for (final c in ['K', '7', 'P', '2', 'Q', 'X']) {
      expect(find.text(c), findsOneWidget);
    }
    expect(find.text('Z'), findsNothing, reason: 'only 6 characters');
    expect(tester.widget<FilledButton>(join()).onPressed, isNotNull);
  });

  testWidgets('each server code shows its own message', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'K7P2QX');
    await tester.pump();

    final messages = {
      const ShopApiException('invite_expired', 410): 'លេខកូដផុតកំណត់ហើយ',
      const ShopApiException('invite_used', 409): 'លេខកូដត្រូវបានប្រើរួចហើយ',
      const ShopApiException('invite_not_found', 404): 'លេខកូដមិនត្រឹមត្រូវ',
      const AppException('offline'):
          'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ។ សូមព្យាយាមម្តងទៀត។',
    };
    for (final MapEntry(key: error, value: text) in messages.entries) {
      api.answer = Err(error);
      await tester.tap(join());
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget, reason: '$error');
    }
    expect(api.codes, everyElement('K7P2QX'));
  });

  testWidgets('a code scanned on Home is filled in and joined at once', (
    tester,
  ) async {
    await pumpPage(tester, code: 'k7p2qx');
    expect(api.codes, ['K7P2QX']);
  });

  test('isInviteCode: six characters of the invite alphabet only', () {
    expect(isInviteCode('K7P2QX'), isTrue);
    expect(isInviteCode('K7P2Q'), isFalse);
    expect(isInviteCode('K7P2QX9'), isFalse);
    expect(isInviteCode('K0P2QX'), isFalse); // no 0, 1, I, O
    expect(isInviteCode('k7p2qx'), isFalse); // the QR holds uppercase
    expect(isInviteCode('8850001'), isFalse); // a product barcode
  });
}

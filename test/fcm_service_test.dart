import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/service/fcm_service.dart';

void main() {
  group('FcmService notification content', () {
    test('formats income payload with clean copy', () {
      final content = FcmService.buildNotificationContentFromPayload({
        'fingerprint': 'income-1',
        'bankKey': 'aba',
        'amount': 25,
        'currency': 'USD',
        'isIncome': true,
      });

      expect(content.title, 'Income received');
      expect(content.body, r'ABA Bank • $ 25');
      expect(content.groupKey, 'income_updates');
    });

    test('formats expense payload with readable khr amount', () {
      final content = FcmService.buildNotificationContentFromPayload({
        'fingerprint': 'expense-1',
        'bankKey': 'acleda',
        'amount': 40000,
        'currency': 'KHR',
        'isIncome': false,
      });

      expect(content.title, 'Expense recorded');
      expect(content.body, 'ACLEDA Bank • KHR 40,000');
    });

    test('uses structured remote message data when available', () {
      final content = FcmService.buildNotificationContentFromRemoteMessage(
        RemoteMessage.fromMap({
          'messageId': 'msg-1',
          'data': {
            'fingerprint': 'income-2',
            'bankKey': 'chip_mong',
            'amount': '18.5',
            'currency': 'USD',
            'isIncome': true,
          },
        }),
      );

      expect(content.title, 'Income received');
      expect(content.body, r'Chip Mong Bank • $ 18.50');
      expect(content.groupKey, 'income_updates');
    });
  });
}

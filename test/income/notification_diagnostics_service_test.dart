import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/income/income.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationTrackingBridge extends Mock
    implements NotificationTrackingBridge {}

void main() {
  test('a second initialize waits for the first load instead of racing it',
      () async {
    final bridge = MockNotificationTrackingBridge();
    final logs = Completer<List<Map<String, dynamic>>>();
    when(bridge.getDiagnosticsLogs).thenAnswer((_) => logs.future);
    when(() => bridge.diagnosticLogStream)
        .thenAnswer((_) => const Stream.empty());
    final service = NotificationDiagnosticsService(bridge);

    var secondDone = false;
    final first = service.initialize();
    unawaited(service.initialize().then((_) => secondDone = true));
    await pumpEventQueue();

    // With the old bool, the second call returned here with no entries.
    expect(secondDone, isFalse);

    logs.complete([
      {'source': 'native', 'message': 'stored before launch'},
    ]);
    await first;
    await pumpEventQueue();

    expect(secondDone, isTrue);
    expect(service.entries.single.message, 'stored before launch');
    verify(bridge.getDiagnosticsLogs).called(1);
  });
}

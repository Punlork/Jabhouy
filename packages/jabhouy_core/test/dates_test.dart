import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:test/test.dart';

void main() {
  test('toIsoDate is date-only and zero-padded', () {
    expect(DateTime(2026, 5, 3, 7).toIsoDate(), '2026-05-03');
  });

  test('toIsoDate keeps the local day instead of converting to UTC', () {
    // 01:00 local in UTC+7 is the previous day in UTC.
    expect(DateTime(2026, 5, 3, 1).toIsoDate(), '2026-05-03');
  });

  test('toPhnomPenh shows UTC in Cambodia time', () {
    final t = DateTime.utc(2026, 10, 16, 4, 5).toPhnomPenh();
    expect([t.year, t.month, t.day, t.hour, t.minute], [2026, 10, 16, 11, 5]);
  });

  test('toPhnomPenh crosses midnight into the next day', () {
    final t = DateTime.utc(2026, 10, 16, 20).toPhnomPenh();
    expect([t.month, t.day, t.hour], [10, 17, 3]);
  });
}

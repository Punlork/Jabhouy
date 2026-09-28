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
}

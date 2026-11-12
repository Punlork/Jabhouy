import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';

void main() {
  final km = lookupAppLocalizations(const Locale('km'));
  final en = lookupAppLocalizations(const Locale('en'));
  // Already in Phnom Penh wall-clock time (see toPhnomPenh in jabhouy_core).
  final morning = DateTime(2026, 10, 16, 11, 5);

  test('Khmer date and time', () {
    expect(km.formatDate(morning), '16 តុលា 2026');
    expect(km.formatTime(morning), '11:05 ព្រឹក');
  });

  test('Khmer time of day by hour', () {
    String at(int h, [int m = 0]) => km.formatTime(DateTime(2026, 1, 1, h, m));
    expect(at(0, 30), '12:30 យប់');
    expect(at(4, 59), '4:59 យប់');
    expect(at(5), '5:00 ព្រឹក');
    expect(at(12), '12:00 រសៀល');
    expect(at(16, 59), '4:59 រសៀល');
    expect(at(17), '5:00 ល្ងាច');
    expect(at(19), '7:00 យប់');
  });

  test('every Khmer month name', () {
    expect(
      [for (var m = 1; m <= 12; m++) km.formatDate(DateTime(2026, m))],
      [
        '1 មករា 2026',
        '1 កុម្ភៈ 2026',
        '1 មីនា 2026',
        '1 មេសា 2026',
        '1 ឧសភា 2026',
        '1 មិថុនា 2026',
        '1 កក្កដា 2026',
        '1 សីហា 2026',
        '1 កញ្ញា 2026',
        '1 តុលា 2026',
        '1 វិច្ឆិកា 2026',
        '1 ធ្នូ 2026',
      ],
    );
  });

  test('English date and time', () {
    expect(en.formatDate(morning), '16 Oct 2026');
    expect(en.formatTime(morning), '11:05 AM');
    expect(en.formatTime(DateTime(2026, 1, 1, 19)), '7:00 PM');
  });
}

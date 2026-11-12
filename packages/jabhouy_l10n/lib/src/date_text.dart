import 'package:jabhouy_l10n/src/arb/app_localizations.dart';

/// Date and time as people read them: `16 តុលា 2026`, `11:05 ព្រឹក`.
/// Pass wall-clock time already in Phnom Penh (`toPhnomPenh()` in core).
extension DateText on AppLocalizations {
  static const _khmerMonths = [
    'មករា',
    'កុម្ភៈ',
    'មីនា',
    'មេសា',
    'ឧសភា',
    'មិថុនា',
    'កក្កដា',
    'សីហា',
    'កញ្ញា',
    'តុលា',
    'វិច្ឆិកា',
    'ធ្នូ',
  ];

  static const _englishMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  bool get _isKhmer => localeName.startsWith('km');

  String formatDate(DateTime d) {
    final months = _isKhmer ? _khmerMonths : _englishMonths;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String formatTime(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = _isKhmer
        ? _khmerPeriod(d.hour)
        : (d.hour < 12 ? 'AM' : 'PM');
    return '$hour12:$minute $period';
  }

  // Morning 05–11, afternoon 12–16, evening 17–18, night 19–04.
  static String _khmerPeriod(int hour) => switch (hour) {
    >= 5 && < 12 => 'ព្រឹក',
    >= 12 && < 17 => 'រសៀល',
    >= 17 && < 19 => 'ល្ងាច',
    _ => 'យប់',
  };
}

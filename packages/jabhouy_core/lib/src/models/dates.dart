/// How dates cross the wire.
library;

extension IsoDate on DateTime {
  /// `YYYY-MM-DD` in this [DateTime]'s own zone, for fields the server
  /// validates as a date rather than a timestamp.
  ///
  /// Deliberately not `toUtc()` first: in Cambodia (UTC+7) a loan made
  /// before 07:00 would land on the previous day.
  String toIsoDate() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

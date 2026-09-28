import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

// The generated copyWith tells "left out" from "passed null" with a
// placeholder default. The analyzer reads the generated interface, whose
// default looks like null, and calls `syncMessage: null` redundant. It is
// not: these tests are what removing it would break.
void main() {
  final loaded = LoanerLoaded(
    PaginatedResponse(items: const [], pagination: Pagination()),
    fromDate: DateTime(2026, 5),
    toDate: DateTime(2026, 5, 31),
    syncMessage: 'Back online. Syncing loaners...',
  );

  test('passing null clears a nullable field', () {
    // ignore: avoid_redundant_argument_values -- the null under test.
    final next = loaded.copyWith(syncMessage: null, fromDate: null);

    expect(next.syncMessage, isNull);
    expect(next.fromDate, isNull);
  });

  test('leaving a field out keeps it', () {
    final next = loaded.copyWith(isOffline: true);

    expect(next.syncMessage, 'Back online. Syncing loaners...');
    expect(next.fromDate, DateTime(2026, 5));
    expect(next.toDate, DateTime(2026, 5, 31));
    expect(next.isOffline, isTrue);
  });
}

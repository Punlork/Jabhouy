import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/loaner/loaner.dart';

void main() {
  test('toJson sends createdAt as a date, which is all PUT /loans accepts', () {
    final loaner = LoanerModel(
      id: 38,
      amount: 0,
      createdAt: DateTime(2026, 5, 3, 7),
    );

    expect(loaner.toJson()['createdAt'], '2026-05-03');
  });
}

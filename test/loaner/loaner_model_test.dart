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

  test('fromJson takes customerId from the nested customer the API sends', () {
    final loaner = LoanerModel.fromJson(const {
      'id': 37,
      'amount': 0,
      'createdAt': '2026-05-03T00:00:00.000Z',
      'customer': {'id': 24, 'name': 'Pa Ah Pnug'},
    });

    expect(loaner.customerId, 24);
    expect(loaner.customer?.name, 'Pa Ah Pnug');
  });
}

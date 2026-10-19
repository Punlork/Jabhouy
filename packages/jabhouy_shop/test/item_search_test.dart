import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';

Item _item(String name, {List<String> nicknames = const []}) =>
    Item(id: name, name: name, nicknames: nicknames, prices: const []);

List<String> _names(List<Item> items, String query) => [
  for (final hit in searchItems(items, query)) hit.item.name,
];

void main() {
  test('a nickname finds its item and says which one matched', () {
    final hits = searchItems([
      _item('ទឹកសុទ្ធ Vital 1.5L', nicknames: ['ទឹកធំ', 'វីតាល់']),
      _item('ទឹកក្រូច'),
    ], 'ទឹកធំ');

    expect(hits.single.item.name, 'ទឹកសុទ្ធ Vital 1.5L');
    expect(hits.single.rank, SearchRank.nickname);
    expect(hits.single.matchedNickname, 'ទឹកធំ');
  });

  test('ranks exact, starts-with, nickname, contains, then fuzzy', () {
    final items = [
      _item('Pepsi coca style'),
      _item('Cpca Max'),
      _item('Fanta', nicknames: ['coca orange']),
      _item('Coca-Cola'),
      _item('coca'),
      _item('Sprite'),
    ];

    expect(_names(items, 'coca'), [
      'coca',
      'Coca-Cola',
      'Fanta',
      'Pepsi coca style',
      'Cpca Max',
    ]);
  });

  test('ties keep name order', () {
    expect(_names([_item('Coke Zero'), _item('Coke')], 'co'), [
      'Coke',
      'Coke Zero',
    ]);
  });

  test('a zero-width space in the query or the name still matches', () {
    final items = [_item('ទឹក​ធំ')];

    expect(_names(items, 'ទឹកធំ'), ['ទឹក​ធំ']);
    expect(_names([_item('ទឹកធំ')], 'ទឹក​ធំ'), ['ទឹកធំ']);
  });

  test('Latin matches ignore case and surrounding spaces', () {
    expect(_names([_item('Coca-Cola')], '  COCA '), ['Coca-Cola']);
  });

  test('one wrong, missing or extra character matches from 4 characters', () {
    final items = [_item('Coca-Cola')];

    expect(_names(items, 'cpca'), ['Coca-Cola'], reason: 'one changed');
    expect(_names(items, 'cca-c'), ['Coca-Cola'], reason: 'one missing');
    expect(_names(items, 'cocaa-'), ['Coca-Cola'], reason: 'one extra');
    expect(_names(items, 'cxxa'), isEmpty, reason: 'two wrong');
  });

  test('a 3-character typo does not fuzzy-match', () {
    expect(_names([_item('Coca-Cola')], 'cpc'), isEmpty);
  });

  test('an empty query keeps every item in order', () {
    final items = [_item('a'), _item('b')];
    expect(_names(items, ' ​ '), ['a', 'b']);
  });
}

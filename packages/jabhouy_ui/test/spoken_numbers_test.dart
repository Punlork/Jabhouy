import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/src/voice/spoken_numbers.dart';

void main() {
  test('Khmer digits become Arabic', () {
    expect(normalizeSpokenNumbers('១២៣'), '123');
    expect(normalizeSpokenNumbers('លុយ ៥០០០ រៀល'), 'លុយ 5000 រៀល');
  });

  test('Khmer number words become digits', () {
    expect(normalizeSpokenNumbers('ពីររយ'), '200');
    expect(normalizeSpokenNumbers('ពីរ រយ'), '200');
    expect(normalizeSpokenNumbers('ប្រាំ ពាន់'), '5000');
    expect(normalizeSpokenNumbers('ម្ភៃប្រាំ'), '25');
    expect(normalizeSpokenNumbers('មួយម៉ឺនពីរពាន់ប្រាំរយ'), '12500');
    expect(normalizeSpokenNumbers('ដប់មួយ'), '11');
  });

  test('English number words become digits', () {
    expect(normalizeSpokenNumbers('twenty five'), '25');
    expect(normalizeSpokenNumbers('two hundred'), '200');
    expect(normalizeSpokenNumbers('Coca two thousand'), 'Coca 2000');
  });

  test('ordinary words and a lone one stay', () {
    expect(normalizeSpokenNumbers('ពីរនាក់'), 'ពីរនាក់');
    expect(normalizeSpokenNumbers('គោលការណ៍ មួយ'), 'គោលការណ៍ មួយ');
    expect(normalizeSpokenNumbers('one'), 'one');
    expect(normalizeSpokenNumbers('Pa Ah Pnug'), 'Pa Ah Pnug');
  });

  test('written digits keep their leading zero', () {
    expect(normalizeSpokenNumbers('០១២៣៤៥'), '012345');
    expect(normalizeSpokenNumbers('012345'), '012345');
  });
}

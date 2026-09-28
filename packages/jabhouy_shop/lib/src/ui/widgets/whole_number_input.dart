import 'package:flutter/services.dart';

/// Khmer digits ០–៩ are U+17E0–U+17E9; a Khmer keyboard types them.
const _khmerZero = 0x17E0;

/// Rewrites Khmer digits as ASCII and drops everything else.
///
/// `int.tryParse` returns null for `១៥០០`, `1,500` or `1500.5`, and the
/// form used to save that null as "no price" without a word.
String normalizeWholeNumber(String raw) {
  final buffer = StringBuffer();
  for (final rune in raw.runes) {
    if (rune >= _khmerZero && rune <= _khmerZero + 9) {
      buffer.writeCharCode(0x30 + rune - _khmerZero);
    } else if (rune >= 0x30 && rune <= 0x39) {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// The number in [raw], or null when there is none.
int? parseWholeNumber(String raw) {
  final digits = normalizeWholeNumber(raw);
  return digits.isEmpty ? null : int.tryParse(digits);
}

/// Keeps a price or amount field to ASCII digits as the seller types or
/// pastes.
class WholeNumberFormatter extends TextInputFormatter {
  const WholeNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = normalizeWholeNumber(newValue.text);
    if (digits == newValue.text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

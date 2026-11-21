/// Makes dictated numbers consistent: the speech engine sometimes writes
/// `២០០` or `200` and sometimes `ពីររយ` or "two hundred". Everything becomes
/// Arabic digits, the way the app shows amounts.
///
/// Conservative on purpose: a chunk (text between spaces) is turned into a
/// number only when the whole chunk is number words, so `ពីរនាក់` and every
/// ordinary word stay as spoken. A lone `មួយ` or "one" also stays: it is
/// mostly "a/an" in a sentence, not a quantity.
String normalizeSpokenNumbers(String text) {
  final withDigits = _khmerDigits(text);
  final chunks = RegExp(r'\S+|\s+').allMatches(withDigits).map((m) => m[0]!);
  final out = StringBuffer();
  final run = <_Token>[];
  var pendingSpace = '';

  void flush() {
    if (run.isEmpty) return;
    final skip = run.length == 1 && run.single.lone;
    if (skip) {
      out
        ..write(pendingSpace)
        ..write(run.single.source);
    } else {
      out
        ..write(pendingSpace)
        ..write(_value(run));
    }
    pendingSpace = '';
    run.clear();
  }

  var spaceBetweenNumbers = '';
  for (final chunk in chunks) {
    if (chunk.trim().isEmpty) {
      spaceBetweenNumbers = chunk;
      continue;
    }
    final tokens = _parse(chunk);
    if (tokens != null) {
      if (run.isEmpty) pendingSpace = spaceBetweenNumbers;
      run.addAll(tokens);
    } else {
      flush();
      out
        ..write(spaceBetweenNumbers)
        ..write(chunk);
    }
    spaceBetweenNumbers = '';
  }
  flush();
  out.write(spaceBetweenNumbers);
  return out.toString();
}

String _khmerDigits(String s) => s.replaceAllMapped(
  RegExp('[០-៩]'),
  (m) => '${m[0]!.codeUnitAt(0) - 0x17E0}',
);

class _Token {
  const _Token(
    this.value,
    this.source, {
    this.magnitude = false,
    this.lone = false,
  });

  final int value;

  /// True for ១០០, ១០០០… words that multiply what came before.
  final bool magnitude;
  final String source;

  /// A word that is not a number on its own (`មួយ`, "one").
  final bool lone;
}

const _khmerWords = <String, int>{
  'សូន្យ': 0,
  'មួយ': 1,
  'ពីរ': 2,
  'បី': 3,
  'បួន': 4,
  'ប្រាំ': 5,
  'ប្រាំមួយ': 6,
  'ប្រាំពីរ': 7,
  'ប្រាំបី': 8,
  'ប្រាំបួន': 9,
  'ដប់': 10,
  'ម្ភៃ': 20,
  'សាមសិប': 30,
  'សែសិប': 40,
  'ហាសិប': 50,
  'ហុកសិប': 60,
  'ចិតសិប': 70,
  'ប៉ែតសិប': 80,
  'កៅសិប': 90,
};

const _khmerMagnitudes = <String, int>{
  'រយ': 100,
  'ពាន់': 1000,
  'ម៉ឺន': 10000,
  'សែន': 100000,
  'លាន': 1000000,
};

const _englishWords = <String, int>{
  'zero': 0,
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
  'twenty': 20,
  'thirty': 30,
  'forty': 40,
  'fifty': 50,
  'sixty': 60,
  'seventy': 70,
  'eighty': 80,
  'ninety': 90,
};

const _englishMagnitudes = <String, int>{
  'hundred': 100,
  'thousand': 1000,
  'million': 1000000,
};

/// The tokens of [chunk] when all of it is number words, else null.
/// Khmer words have no spaces, so a chunk may hold several (`ពីររយ`).
List<_Token>? _parse(String chunk) {
  final lower = chunk.toLowerCase();
  // Digits stay as written: a phone number's leading zero must survive.
  final english = _englishWords[lower];
  if (english != null) {
    return [_Token(english, chunk, lone: lower == 'one')];
  }
  final englishMag = _englishMagnitudes[lower];
  if (englishMag != null) return [_Token(englishMag, chunk, magnitude: true)];

  final tokens = <_Token>[];
  var i = 0;
  while (i < chunk.length) {
    _Token? best;
    var bestLength = 0;
    for (final entry in _khmerWords.entries) {
      if (entry.key.length > bestLength && chunk.startsWith(entry.key, i)) {
        best = _Token(entry.value, entry.key, lone: entry.key == 'មួយ');
        bestLength = entry.key.length;
      }
    }
    for (final entry in _khmerMagnitudes.entries) {
      if (entry.key.length > bestLength && chunk.startsWith(entry.key, i)) {
        best = _Token(entry.value, entry.key, magnitude: true);
        bestLength = entry.key.length;
      }
    }
    if (best == null) return null;
    tokens.add(best);
    i += bestLength;
  }
  return tokens.isEmpty ? null : tokens;
}

int _value(List<_Token> tokens) {
  var total = 0;
  var chunk = 0;
  var current = 0;
  for (final t in tokens) {
    if (!t.magnitude) {
      current += t.value;
    } else if (t.value == 100) {
      chunk += (current == 0 ? 1 : current) * 100;
      current = 0;
    } else {
      final group = chunk + current;
      total += (group == 0 ? 1 : group) * t.value;
      chunk = 0;
      current = 0;
    }
  }
  return total + chunk + current;
}

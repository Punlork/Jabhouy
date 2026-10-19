import 'dart:math';

import 'package:jabhouy_shop/src/models/item.dart';

/// How an Item matched a search, best first (decision 42).
enum SearchRank { exact, startsWith, nickname, contains, fuzzy }

class SearchHit {
  const SearchHit(this.item, this.rank, {this.matchedNickname});

  final Item item;
  final SearchRank rank;

  /// The nickname that matched, for `ឈ្មោះផ្សេង៖ …`; null for a name match.
  final String? matchedNickname;
}

final _zeroWidth = RegExp('[​‌‍﻿]');

/// Drops zero-width spaces (Khmer keyboards insert them), trims, and
/// lowercases Latin.
String normalizeSearch(String text) =>
    text.replaceAll(_zeroWidth, '').trim().toLowerCase();

/// The [items] matching [query], best rank first, then by name. Fuzzy
/// allows one changed, missing or extra character, for queries of 4+.
List<SearchHit> searchItems(List<Item> items, String query) {
  final q = normalizeSearch(query);
  return [
    for (final item in items)
      if (_match(item, q) case final hit?) hit,
  ]..sort((a, b) {
    final byRank = a.rank.index.compareTo(b.rank.index);
    if (byRank != 0) return byRank;
    return normalizeSearch(a.item.name).compareTo(normalizeSearch(b.item.name));
  });
}

SearchHit? _match(Item item, String q) {
  final name = normalizeSearch(item.name);
  if (name == q) return SearchHit(item, SearchRank.exact);
  if (name.startsWith(q)) return SearchHit(item, SearchRank.startsWith);
  for (final nickname in item.nicknames) {
    if (normalizeSearch(nickname).contains(q)) {
      return SearchHit(item, SearchRank.nickname, matchedNickname: nickname);
    }
  }
  if (name.contains(q)) return SearchHit(item, SearchRank.contains);
  if (q.runes.length < 4) return null;
  if (_withinOneEdit(q, name)) return SearchHit(item, SearchRank.fuzzy);
  for (final nickname in item.nicknames) {
    if (_withinOneEdit(q, normalizeSearch(nickname))) {
      return SearchHit(item, SearchRank.fuzzy, matchedNickname: nickname);
    }
  }
  return null;
}

/// True when some stretch of [text] is at most one edit from [query]:
/// edit distance where the match may start and end anywhere in [text].
/// Counts code points, so a Khmer consonant + subscript is two.
bool _withinOneEdit(String query, String text) {
  final q = query.runes.toList();
  final t = text.runes.toList();
  // row[j]: fewest edits to match q[0..i) ending at t[j]; row 0 is free.
  var row = List.filled(t.length + 1, 0);
  for (var i = 1; i <= q.length; i++) {
    final next = List.filled(t.length + 1, i);
    for (var j = 1; j <= t.length; j++) {
      next[j] = min(
        min(row[j] + 1, next[j - 1] + 1),
        row[j - 1] + (q[i - 1] == t[j - 1] ? 0 : 1),
      );
    }
    row = next;
  }
  return row.reduce(min) <= 1;
}

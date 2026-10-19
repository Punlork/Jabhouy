# P3a Step 2: Ranked search with nicknames

Status: done
Blocked by: 19

- Pure Dart in `jabhouy_shop` (no Flutter): normalize (strip zero-width spaces, trim, lowercase Latin), then rank exact → starts-with → nickname → contains → fuzzy (one wrong character, queries of 4+ characters only). Decision 42.
- Each result says which nickname matched, for `ឈ្មោះផ្សេង៖ …` with the match highlighted.

**Done when:** tests show `ទឹកធំ` finds the Item whose nickname is `ទឹកធំ`; the ranking order holds; a zero-width space in the query or name does not break a match; a 3-character typo does not fuzzy-match.

## Comments

- 2026-10-19: `searchItems` / `normalizeSearch` in `jabhouy_shop/lib/src/logic/item_search.dart`, no dependency. Fuzzy is edit distance ≤ 1 against any stretch of the name or a nickname, counted in code points (a Khmer consonant + subscript is two). `ItemRepository.watchItems(search:)` ranks in memory; the SQL `LIKE` is gone. `SearchHit.matchedNickname` is ready for issue 23 to show `ឈ្មោះផ្សេង៖ …`.
- 2026-10-19: Deferred: Khmer typing-order normalization (ុំ/ំុ, subscript order, split vowels េ+ា→ោ). Build only if testers typing 5–10 real item names show stored text differing from saved names.

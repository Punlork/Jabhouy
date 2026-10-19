# P3a Step 2: Ranked search with nicknames

Status: open
Blocked by: 19

- Pure Dart in `jabhouy_shop` (no Flutter): normalize (strip zero-width spaces, trim, lowercase Latin), then rank exact → starts-with → nickname → contains → fuzzy (one wrong character, queries of 4+ characters only). Decision 42.
- Each result says which nickname matched, for `ឈ្មោះផ្សេង៖ …` with the match highlighted.

**Done when:** tests show `ទឹកធំ` finds the Item whose nickname is `ទឹកធំ`; the ranking order holds; a zero-width space in the query or name does not break a match; a 3-character typo does not fuzzy-match.

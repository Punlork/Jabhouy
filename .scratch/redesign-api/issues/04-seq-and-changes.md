# Per-Shop counter and GET /changes

Status: open
Blocked by: 03

- Every write takes the next `shop_seq` value in the same transaction and stores it on the row.
- `GET /shops/:shopId/changes?since=&limit=` as in the spec: rows with `seq > since`, oldest first, tombstones included, `cursor`, `hasMore`; `settings` and `members` when changed.

**Done when:** tests show that after writes A, B, a delete of A, `since=0` returns B and A's tombstone; `since=<cursor>` after that returns nothing; `limit` pages correctly.

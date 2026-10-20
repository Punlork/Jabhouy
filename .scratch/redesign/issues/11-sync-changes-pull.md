# P3 Step 2: Sync with /changes and shop routes

Status: built against the in-memory server (uncommitted); real API pending
Blocked by: 09, 10

- Replace the per-feature `pullAll()` with one pull per Active Shop: `GET /shops/:id/changes?since=<cursor>`, paging on `hasMore`, routing rows to each DAO; tombstones delete locally. One cursor per Shop (decision 36).
- Push adapters `PUT` / `DELETE /shops/:id/<type>/:id`, re-reading the row each attempt (existing rule).
- 403 `forbidden_role`: drop the job, pull again, show `syncNoPermission`. 403 `not_member`: wipe that Shop. 409: drop and pull. Never retried (decision 11).
- Built and tested against a fake transport; switched to the real API when jabhouy-api #3–#8 are live.

**Done when:** `jabhouy_sync` tests cover paging, tombstones, cursor per shop, and each 403/409 rule.

## Comments

- **Swap point:** `ShopSyncApi` (jabhouy_sync) is the one seam: `changes` + `put` + `delete`. `lib/app/injection/dependency_injection.dart` registers `InMemoryShopSyncApi`; going live = register an HTTP implementation there. Nothing else changes.
- **Response shape I assumed** (the contract names only `cursor`/`hasMore`): `{ cursor, hasMore, items: [], categories: [], settings: {…} }`, each row with `seq`, `updatedAt`, `updatedBy`, `deletedAt`. Confirm or correct on jabhouy-api #2/#6; the shape lives in `ChangesPage` only.
- **Engine:** `SyncEngine.pullShop(shopId)` pages from the Shop's cursor and applies each page with the cursor move in one transaction. Rows with a queued local job are skipped. New table `shop_sync_cursors` (schema 11; the release-time old-table drop moves to 12).
- **Server rules:** `SyncPushDropped` (403 `forbidden_role` / `not_member`, 409): job dropped, never retried; `forbidden_role` shows `syncNoPermission` and re-reads the Shop from seq 0 (the pull had skipped the queued row); `not_member` wipes that Shop (`AppDatabase.wipeShop`).
- **Dormant until /me is live:** `ShopScope.syncs` is false for the stand-in Shop, so nothing is queued or pulled in the app today. Tests set it true (two phones, one server: `shop_sync_test.dart`).
- In-memory server loses its rows on restart (the phone keeps its own); fine until HTTP.
- Old per-feature `pullAll` adapters stay for the old tables.

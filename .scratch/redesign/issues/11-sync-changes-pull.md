# P3 Step 2: Sync with /changes and shop routes

Status: open
Blocked by: 09, 10

- Replace the per-feature `pullAll()` with one pull per Active Shop: `GET /shops/:id/changes?since=<cursor>`, paging on `hasMore`, routing rows to each DAO; tombstones delete locally. One cursor per Shop (decision 36).
- Push adapters `PUT` / `DELETE /shops/:id/<type>/:id`, re-reading the row each attempt (existing rule).
- 403 `forbidden_role`: drop the job, pull again, show `syncNoPermission`. 403 `not_member`: wipe that Shop. 409: drop and pull. Never retried (decision 11).
- Built and tested against a fake transport; switched to the real API when jabhouy-api #3–#8 are live.

**Done when:** `jabhouy_sync` tests cover paging, tombstones, cursor per shop, and each 403/409 rule.

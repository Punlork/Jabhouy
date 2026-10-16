# Offline-first shared Shops with last-write-wins

Several Members' phones edit one Shop, often offline at the counter. Each phone writes to its local database first and syncs later; the server keeps the latest write it receives per row, and a per-Shop counter (`seq`) orders changes for pulls because Worker clocks can disagree, and IDs are UUIDv7 created on the phone. A write the server refuses (403, role changed or Member removed) never happened: the phone drops it, pulls the server's row again, and a removed Member's phone wipes that Shop's data. The sync rules live in a contract the app owner writes (`.scratch/redesign-api/spec.md`) and the API owner implements.

## Considered Options

- **Online-only writes, cached reads.** Simpler roles and invites, but no offline Credit entry at the counter and the sync engine shrinks to a cache.
- **Per-field merging or counters that merge.** Correct for concurrent edits, but too much machinery for a shop app; values that would need merging (unit usage) are counted on the phone from synced rows instead.
- **Server-assigned integer IDs.** Collide when two phones create rows offline; switched during the clean start because there is no data to migrate.

## Consequences

- Every synced value must be safe to overwrite whole. No stored counters or running totals.
- Anything visible to one Member is visible to all, because sync sends whole rows (cost price included). Hiding a field per role means moving it into its own entity type.

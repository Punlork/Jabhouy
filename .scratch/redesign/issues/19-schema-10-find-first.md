# P3a Step 1: Schema 10 for nicknames, barcodes and Recently viewed

Status: resolved
Blocked by: 09

- `item.nicknames` (JSON text list, default `[]`), `item_price.barcode` (nullable text), and a local `recent_item` table (`shop_id`, `item_id`, `viewed_at`; never synced). Decisions 45, 46.
- `schemaVersion` 10 with an add-column/create-table migration; the old-table drop moves to 11 (decision 45).
- Item mapping in `ItemDao` / `ItemRepository` carries `nicknames` and `barcode` (no Item sync adapter exists yet; issue 11 adds it).
- `melos run gen`; commit the generated code.

**Done when:** a migration test opens a v9 database with an item, upgrades to 10 with the item intact and `nicknames` empty; a repository test round-trips nicknames and a barcode.

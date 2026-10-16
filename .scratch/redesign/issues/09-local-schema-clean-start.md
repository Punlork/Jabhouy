# P3 Step 1: Local schema 9 (clean start)

Status: open
Blocked by: none

- `AppDatabase` schemaVersion 9: drop every business table and clear the outbox and sync cursors; keep `BankNotifications` (decisions 4, 26).
- New tables matching jabhouy-api #3: `items`, `item_prices`, `categories`, `category_units`, `customers`, `credits`, `credit_items`, `shop_settings`, `members`. Text UUID keys, `shop_id`, `seq`, `updated_at`, `updated_by`, `deleted_at`; money as integers.
- UUIDv7 generator in `jabhouy_core` (about 15 lines with `Random.secure`; no new package).
- `melos run gen`; commit the generated code.

**Done when:** a migration test opens a v8 database with data, upgrades to 9, keeps bank notifications, and has empty new tables; UUIDv7 tests check format and time order.

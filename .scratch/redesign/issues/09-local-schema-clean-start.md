# P3 Step 1: Local schema 9 (new tables beside the old)

Status: resolved
Blocked by: none

- `AppDatabase` schemaVersion 9 adds the new tables; old tables stay so current screens keep working. Version 10 drops them at release (decision 26).
- New tables matching jabhouy-api #3, with its singular SQL names: `item`, `item_price`, `category`, `category_unit`, `customer`, `credit`, `credit_item`, `shop_settings`, `member`. Text UUID keys, `shop_id`, `seq`, `updated_at`, `updated_by`, `deleted_at`; money as integers.
- UUIDv7 generator in `jabhouy_core` (about 15 lines with `Random.secure`; no new package).
- `melos run gen`; commit the generated code.

**Done when:** a migration test opens a v8 database with data, upgrades to 9 with old rows intact, and has the new tables empty; UUIDv7 tests check format and time order.

# Back up current data and start the new schema

Status: open
Blocked by: none

Part of: Redesign API contract (#spec)

- Export the current D1 tables (`category`, `customer`, `item`, `loan`) to CSV for dev and production (`wrangler d1 export`), and keep the files outside the repo.
- Drop those tables and their routes (`/items`, `/categories`, `/customers`, `/loans`). Keep Better Auth's `user`, `account`, `session`, `verification`.
- New Drizzle schema: `shop`, `member`, `shop_settings`, `shop_seq`, `item`, `price_option`, `category`, `category_unit`, `customer`, `credit`, `credit_line`. Text UUID keys; `shop_id`, `seq`, `updated_at`, `updated_by`, `deleted_at` on every business table; money as integers.

**Done when:** `db:migrate:local` builds the new schema from empty, and the CSV backups exist.

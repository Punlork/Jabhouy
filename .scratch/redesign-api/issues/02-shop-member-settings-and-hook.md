# Shop, Member, ShopSettings and the sign-up hook

Status: open
Blocked by: 01

- Better Auth `databaseHooks.user.create.after`: in one transaction create a Shop, the owner Member, ShopSettings with the spec's defaults, and the starter Categories with units.
- `GET /me` returns the user and their shops with role.
- `GET` / `PUT /shops/:shopId/settings` (PUT owner only); the server sets `rateUpdatedAt` / `rateUpdatedBy` when `khrPerUsd` changes.

**Done when:** signing up (password or Google) gives exactly one Shop with owner role, and `GET /me` shows it.

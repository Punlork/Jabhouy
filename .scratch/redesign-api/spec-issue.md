# Redesign API contract

Draft of the pinned GitHub issue on `sokhengpory/jabhouy-api`. The app is offline-first: phones write locally, queue changes, and sync with this API. This issue is the contract both sides build against. Comment on anything that is wrong or hard to build.

Background: clean start, no migration and no compatibility with the current API (only the app owner uses it). Every old business table is dropped.

## Principles

- **Shop-scoped.** Every business row belongs to a Shop. Every route under `/shops/:shopId` checks that the caller is a Member of that Shop.
- **The phone makes the IDs.** IDs are UUIDv7 strings created on the phone. The server never assigns business IDs.
- **Upsert, never create/update.** `PUT` with a client ID creates or replaces. Sending the same request twice gives the same result (the phone retries after timeouts).
- **Last write wins per row.** The server keeps the latest `PUT` it receives for a row. No merging, except units (see Categories).
- **Deletes are tombstones.** `DELETE` sets `deletedAt`; the row still appears in pulls so other phones learn about it. Deleting twice is fine.
- **The server sets bookkeeping fields.** `updatedAt`, `updatedBy`, `seq` and `deletedAt` are ignored in request bodies.

## Formats

| What | Format | Example |
|---|---|---|
| IDs | UUIDv7 string | `"01929d3e-…"` |
| Money | whole number in the smallest unit (riel, or cents), always next to a `currency` | `"price": 750, "currency": "USD"` = $7.50 |
| Currency | `"KHR"` or `"USD"` | |
| Timestamp | ISO 8601 UTC with `Z` | `"2026-10-16T04:05:00.000Z"` |
| Date only | `YYYY-MM-DD` (the phone sends the local day) | `"2026-10-20"` |
| JSON keys | camelCase, as today | |
| Errors | `{ "code": "...", "message": "..." }` | |

Money is never a decimal: validation rejects `7.50` with 400.

## Roles

| Action | owner | editor | viewer |
|---|---|---|---|
| Read everything in the Shop (cost price included) | ✓ | ✓ | ✓ |
| Upsert / delete Items, Categories (and units) | ✓ | ✓ | |
| Upsert Customers, upsert Credits (incl. mark paid) | ✓ | ✓ | ✓ |
| Delete Customers, delete Credits | ✓ | ✓ | |
| Change ShopSettings | ✓ | | |

## Errors

| Status | `code` | When | What the phone does |
|---|---|---|---|
| 400 | `invalid` | Body fails validation | Keeps the job failed; retried after an app fix |
| 401 | `unauthorized` | No or expired session | Signs in again |
| 403 | `not_member` | Caller is not a Member of `:shopId` | Wipes that Shop's local data |
| 403 | `forbidden_role` | Role cannot do this action | Drops the job, pulls again, shows a message |
| 409 | `customer_has_credits` | Delete a Customer who still has Credits (deleted Credits don't count) | Drops the job, pulls again |

403 and 409 are final: the phone never retries them.

## Entities

Every entity response includes `id`, `updatedAt`, `updatedBy` (user id), `deletedAt` (null unless deleted).

### Item (with its prices)

```json
{
  "id": "…", "name": "Coca-Cola", "categoryId": "…|null", "photoUrl": null, "note": null,
  "prices": [
    { "id": "…", "unit": "ដប", "packQty": null, "currency": "KHR",
      "price": 3000, "wholesale": null, "cost": 2500, "sortOrder": 0 },
    { "id": "…", "unit": "កេះ", "packQty": 24, "currency": "KHR",
      "price": 60000, "wholesale": null, "cost": null, "sortOrder": 1 }
  ]
}
```

- Each entry in `prices` is one way the Item is sold (a Price option): a unit, an optional pack size, and its selling, wholesale and cost price in one currency.
- `PUT` replaces the whole `prices` list (entries missing from the body are removed).
- At least one entry. `price`, `wholesale`, `cost` are nullable: null means "no price yet", never 0.
- A `unit` not yet among the Category's units is added to that Category's units.

### Category (with its units)

```json
{ "id": "…", "name": "ភេសជ្ជៈ", "sortOrder": 0, "hidden": false,
  "units": [ { "unit": "ដប", "hidden": false }, { "unit": "កេះ", "hidden": false } ] }
```

- `units` are the unit names suggested as chips when adding an Item in this Category.
- A unit's identity is `(categoryId, unit)`.
- Units **merge**: a `PUT` adds any unit it names and updates `hidden` on the ones it names, but never removes a unit it leaves out. Two phones adding different units offline both keep theirs.
- Units are hidden, never deleted.

### Customer

```json
{ "id": "…", "name": "សុខា", "phone": null, "note": null }
```

### Credit (with its items)

```json
{
  "id": "…", "customer": { "id": "…" },
  "currency": "KHR", "amount": 25000, "khrPerUsd": 4000,
  "status": "unpaid", "takenAt": "2026-10-16T04:05:00.000Z", "dueDate": null,
  "paidAt": null, "note": null,
  "items": [
    { "id": "…", "priceId": "…|null", "name": "Coca-Cola", "unit": "ដប",
      "qty": 2, "currency": "KHR", "unitPrice": 3000, "total": 6000 }
  ]
}
```

- `customer.id` is required and must be a live Customer of the Shop.
- `khrPerUsd` is the Shop's rate at the moment the Credit was made. It never follows later rate changes.
- `PUT` replaces the whole `items` list.
- `items` are copies taken at the time: later price changes never alter them. `priceId` points to the Item's price entry it came from, and may point to a deleted one.
- `total` = `qty × unitPrice`, converted to the Credit's currency with the Credit's `khrPerUsd` **per item**, then rounded (KHR to the nearest 100, USD to the nearest cent).
- With items: `amount` must equal the sum of `total`. Without items: `amount` is free, or null ("no amount yet").
- The server checks both rules and answers 400 on a mismatch; it does not correct the body.
- `paidAt` is set by the phone when status becomes `paid`, and cleared when it goes back to `unpaid`.

### ShopSettings (one per Shop)

```json
{ "useWholesalePrice": false, "useCostPrice": true, "defaultCurrency": "KHR",
  "khrPerUsd": 4000, "showConverted": true, "rateUpdatedAt": "…", "rateUpdatedBy": "…" }
```

`rateUpdatedAt` / `rateUpdatedBy` are set by the server when `khrPerUsd` changes.

## Conversion (shared rule)

Same function on the phone (`jabhouy_core`) and the server, with the same tests:

- USD → KHR: `round_half_up(cents × khrPerUsd / 100, to 100)`
- KHR → USD: `round_half_up(riel × 100 / khrPerUsd)` cents

Test cases at 4,000: $7.50 → 30,000 ៛; 3,800 ៛ → $0.95; $1.23 → 4,900 ៛.

## Routes

| Method | Path | Who | What it does |
|---|---|---|---|
| `*` | `/auth/*` | anyone | Better Auth, unchanged: sign up, sign in (password or Google), sign out, session, Username check. |
| GET | `/me` | signed in | The signed-in user and their Shops with role: `{ user, shops: [{ id, name, role }] }`. The app calls it after sign-in to pick the Shop. |
| GET | `/shops/:shopId/changes` | Member | Everything that changed in the Shop since a cursor, deletes included. The only way the app reads business data. See "Pull of changes". |
| PUT | `/shops/:shopId/items/:id` | owner, editor | Create or replace an Item and its full `prices` list. Returns the stored Item. |
| DELETE | `/shops/:shopId/items/:id` | owner, editor | Mark the Item and its prices deleted. 204. |
| PUT | `/shops/:shopId/categories/:id` | owner, editor | Create or replace a Category; merge its `units`. Returns the stored Category. |
| DELETE | `/shops/:shopId/categories/:id` | owner, editor | Mark the Category deleted; its Items keep their `categoryId`. 204. |
| PUT | `/shops/:shopId/customers/:id` | any Member | Create or replace a Customer. Returns the stored Customer. |
| DELETE | `/shops/:shopId/customers/:id` | owner, editor | Mark the Customer deleted; 409 `customer_has_credits` if a live Credit points to them. 204. |
| PUT | `/shops/:shopId/credits/:id` | any Member | Create or replace a Credit and its full `items` list; checks the totals. Returns the stored Credit. |
| DELETE | `/shops/:shopId/credits/:id` | owner, editor | Mark the Credit and its items deleted. 204. |
| GET | `/shops/:shopId/settings` | Member | The Shop's settings. |
| PUT | `/shops/:shopId/settings` | owner | Replace the settings; stamps `rateUpdatedAt` / `rateUpdatedBy` when the rate changes. Returns the stored settings. |

## Pull of changes

```json
GET /shops/:shopId/changes?since=0&limit=500
{
  "items": [...], "categories": [...], "customers": [...], "credits": [...],
  "settings": {...} | null, "members": [{ "userId": "…", "displayName": "…", "role": "owner" }],
  "cursor": "1234", "hasMore": false
}
```

- Every write in a Shop takes the next value of a per-Shop counter (`seq`), stored on the row, in the same transaction as the write.
- The response holds rows with `seq > since`, oldest first, deletes included, at most `limit` rows. `cursor` is the highest `seq` returned; the phone sends it back as `since`.
- `since=0` returns everything (first sync after sign-in).
- Why not `updatedAt` as the cursor: two Workers can have slightly different clocks, so a later write could get an earlier time and be skipped. A counter never goes backwards.
- `settings` and `members` are included when they changed since `since`.

## Shop creation (until family sharing)

A Better Auth `databaseHooks.user.create.after` hook creates, in one transaction: a `Shop` (name from the user's name), the owner `Member`, `ShopSettings` (KHR, 4,000, show converted on, wholesale off, cost on) and the starter Categories with units (list to be confirmed). The hook is removed when invites and shop choice ship.

## Out of scope for now

Invites, joining, role changes and member removal (family sharing, later phase). Income / bank notifications. Password reset. Price history.

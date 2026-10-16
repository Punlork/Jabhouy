Clean start: drop the old business tables and routes, keep Better Auth. The app is offline-first, so the API only needs **upsert, delete, and "what changed"**.

## Order

Do the steps in order; each one needs the one above it. Step 5 is three separate issues that can be done in any order.

| Step | Issue | What |
|---|---|---|
| 1 | #3 | Back up data, new schema |
| 2 | #4 | Shop, Member, settings, sign-up hook, `/me` |
| 3 | #5 | Membership and role checks |
| 4 | #6 | `seq` counter and `GET /changes` |
| 5 | #7 · #8 · #9 | Items · Categories · Customers |
| 6 | #10 | Credits and the money conversion (needs #9) |

## Rules

1. Everything lives under `/shops/:shopId`; the caller must be a Member (else 403 `not_member`).
2. IDs are UUIDv7 made by the phone. `PUT` creates or replaces; sending it twice is harmless.
3. `DELETE` sets `deletedAt` (tombstone), never removes the row.
4. Every write takes the next per-Shop number `seq`; `GET /changes?since=<seq>` returns rows with a higher `seq`, deletes included.
5. Money is a whole number in riel or cents, always with `currency` (`KHR`/`USD`). Timestamps are ISO UTC; `dueDate` is `YYYY-MM-DD`.
6. The server sets `updatedAt`, `updatedBy`, `deletedAt`, `seq`.
7. Errors: `{ code, message }`. 403 `forbidden_role` when a role can't do something; 409 `customer_has_credits`.

## Routes

| Route | Who | Does |
|---|---|---|
| `GET /me` | signed in | User and their Shops with role |
| `GET /shops/:id/changes?since=&limit=` | Member | Everything changed since `since`, plus `cursor`, `hasMore` |
| `PUT/DELETE /shops/:id/items/:itemId` | owner, editor | Item with its `prices` list |
| `PUT/DELETE /shops/:id/categories/:catId` | owner, editor | Category with its `units` |
| `PUT /shops/:id/customers/:custId` · `DELETE` | any Member · owner, editor | Customer; delete refused while it has Credits |
| `PUT /shops/:id/credits/:creditId` · `DELETE` | any Member · owner, editor | Credit with its `items` list |
| `PUT /shops/:id/settings` | owner | Settings |

A Better Auth `user.create.after` hook creates the user's Shop, owner Member, settings and starter categories.

## Shapes

```json
// Item
{ "id": "…", "name": "Coca-Cola", "categoryId": "…", "photoUrl": null, "note": null,
  "prices": [{ "id": "…", "unit": "ដប", "packQty": null, "currency": "KHR",
               "price": 3000, "wholesale": null, "cost": 2500, "sortOrder": 0 }] }

// Category — units are only ever added or hidden, never removed by a PUT
{ "id": "…", "name": "ភេសជ្ជៈ", "sortOrder": 0, "hidden": false,
  "units": [{ "unit": "ដប", "hidden": false }] }

// Customer
{ "id": "…", "name": "សុខា", "phone": null, "note": null }

// Credit — khrPerUsd is the rate when it was made
{ "id": "…", "customer": { "id": "…" }, "currency": "KHR", "amount": 6000, "khrPerUsd": 4000,
  "status": "unpaid", "takenAt": "2026-10-16T04:05:00.000Z", "dueDate": null, "paidAt": null, "note": null,
  "items": [{ "id": "…", "priceId": "…", "name": "Coca-Cola", "unit": "ដប",
              "qty": 2, "currency": "KHR", "unitPrice": 3000, "total": 6000 }] }

// Settings
{ "useWholesalePrice": false, "useCostPrice": true, "defaultCurrency": "KHR",
  "khrPerUsd": 4000, "showConverted": true }
```

Nullable prices mean "no price yet", never 0. A `PUT` replaces the whole `prices` / `items` list.

**Later, not now:** invites and joining, password reset, income.

Full reasoning, if needed: the app repo's `docs/adr/0001-offline-first-shared-shops.md`.

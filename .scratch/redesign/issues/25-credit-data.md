# P4 Step 1: Credit data, money rules and sync

Status: done (uncommitted)
Blocked by: 11

- `lib/credit/` feature: `CreditRepository`, `CustomerRepository`, DAO over schema-9 `customer`, `credit`, `credit_item`. Writes go to Drift, then `SyncEngine.enqueue`.
- New `SyncEntityType`s for the redesign customer and credit; push adapters and `/changes` appliers through `ShopSyncApi` (credit items replace as a set, decision 27).
- Money (decisions 30, 32): a Credit has one currency; a line in the other currency converts and rounds per line (100 ៛ / 1 cent) with the rate snapshot taken at creation; amount = sum of lines, typed only with no lines; totals convert each Credit with its own snapshot.
- Roles: every Member adds, edits and marks paid; only owner and editor delete (decision 14). A Customer with any Credit cannot be deleted; delete is owner and editor only (decision 33).
- Times stored UTC, shown UTC+7.

**Done when:** a test makes 2 × ដប (3,000) + 5 × គីឡូ (3,800) = 25,000 ៛ (≈ $6.25 at 4,000); a USD line converts per line; changing the shop rate afterwards changes neither that Credit nor the summary total; a Customer with Credits is refused deletion; a viewer cannot delete a Credit.

## Comments

- `lib/credit/`: `models/credit.dart`, `logic/credit_money.dart` (pure), `data/{credit_dao,credit_repository,credit_sync}.dart`, barrel `credit.dart`. Model is `CreditCustomer`, since the old `Customers` table already owns the row class `Customer`.
- New `SyncEntityType`s `creditCustomer` and `credit`; adapters and appliers registered in DI beside the shop's, through `ShopSyncApi`. Customer is applied before Credit.
- A Credit's amount with lines is their sum, set on save (so the list needs no lines); the form reads the rate once via `currentRates()` and the Credit keeps it.
- Drift returns local-zone times; the DAO converts to UTC on read (a test caught it). Screens convert to UTC+7 for display.
- Dormant like issue 11: `syncs` is false for the stand-in Shop, and nothing uses the repository until issue 26.

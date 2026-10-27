# Spec: integrate the app with the redesigned API

Status: draft

## Problem

The app is built for `/shops/:id/…` + `GET /changes` + `GET /me` (spec-issue-short.md). The API today has the four resources (items, categories, customers, credits) on user-scoped routes `/items/:id` etc.; shops, roles, `/changes`, `/me` are the friend's work (jabhouy-api #3 to #6). So the contract is split across two states and the app must work against both.

## The seam (already in the app)

`ShopSyncApi` (`packages/jabhouy_sync`): `put`, `delete`, `changes`. Adapters, appliers and bodies do not change between states; only the registered implementation does (`dependency_injection.dart`).

| State | `ShopSyncApi` | `MeApi` | Flags |
|---|---|---|---|
| Offline only (now in dev/prod) | `InMemoryShopSyncApi` | `FakeMeApi` | all off |
| Phase 1: local, user-scoped routes | `UserScopedShopSyncApi` (push only) | `FakeMeApi` | `FEATURE_USER_SCOPED_API` |
| Phase 2: shops live | `HttpShopSyncApi` (new) | `HttpMeApi` | `FEATURE_SERVER_SHOPS` |

## Where the API differs from the final contract (spec-issue-short.md, "Current implementation")

The adapters keep the final contract (cents, `YYYY-MM-DD`); `UserScopedShopSyncApi.toApiBody` converts, so Phase 2 deletes the conversion with the class.

- Money: the API takes decimals (USD `12.5`); the app sends cents, so USD amounts are divided by 100 (item prices, credit `amount`, line `unitPrice` and `total`). KHR is unchanged.
- `dueDate` is an ISO datetime; the app's date-only day goes as local midnight in UTC. `takenAt`/`paidAt` already are.
- No `/changes`, `/me`, roles: pull is off, `forbidden_role` never comes.

## Phase 1: verify the four write contracts locally (done in code, not yet run)

Run "Local API" (iOS simulator; Android emulator after `adb reverse tcp:8788 tcp:8788`). Needs the API's `BETTER_AUTH_URL=http://localhost:8788`.

Per resource (category, customer, item, credit), check on the API's local D1:
1. Create in app → row appears, body accepted (no 400).
2. Edit → same id, replaced; double `PUT` harmless.
3. Delete → tombstone (`deletedAt`), later `GET` 404.
4. Offline create, reconnect → outbox drains in order (category before item, customer before credit).

Specific risks the handoff listed as unverified:
- Ids are UUIDv7 strings and timestamps ISO UTC (`takenAt`, `dueDate`, `paidAt`).
- Credit with a USD line; `total` mismatch gives 400 and the app must park it, not retry forever.
- Customer delete while it has credits gives 409 `customer_has_credits`; the app maps 409 to a dropped job. Check the UI says why.
- Unknown `customer.id` gives 400.
- Shop settings have no route: skipped.

Exit: every row above passes, or a mismatch is written up as an issue on the side that must change.

## Phase 2: when jabhouy-api #3 to #6 land

1. Add `HttpShopSyncApi` in the app: `PUT/DELETE /shops/:id/<segment>/:id`, `GET /shops/:id/changes?since&limit` → `ChangesPage`; parse `{code,message}` into `ShopApiException` so `forbidden_role` and `not_member` reach `outcomeForShopWrite`. Segment map: item→items, itemCategory→categories, creditCustomer→customers, credit→credits, shopSettings→settings.
2. Turn on `FEATURE_SERVER_SHOPS` and register `HttpShopSyncApi` under it.
3. Delete `UserScopedShopSyncApi` and `FEATURE_USER_SCOPED_API`.
4. Re-run the Phase 1 checks, plus: second device pulls via `/changes`, tombstones hide rows, rows with a queued local job are skipped by appliers.

Rows written under the fake shop id do not sync after the switch (feature_flags.dart note); the release clean start wipes them.

## Out of scope

Invites and joining, password reset, income, dev or prod deploys, the old `/loans` and `/loaner` routes.

## Open questions

- Does the API author want the user-scoped routes kept after shops land, or replaced by `/shops/:id/…`? Decides whether Phase 2 step 3 happens in the API or only the app.
- Should the app drop 400s from the API (bad body) or park them visibly? Today `outcomeFor` decides; confirm it is not an infinite retry.

# Syncing in the background

**Status:** Implemented
**Author:** Punlork
**Updated:** 2026-09-28

## Summary

Saving a record returns as soon as it is written to the phone, and lists stop calling the server when the seller searches, filters, scrolls or opens a tab.
The sync engine does all network work in the background: it pushes queued writes, and it gains a pull side that downloads each list whole at most once per staleness window.
It runs one push or pull at a time, and a pull never overwrites or deletes a row that still has a job in the outbox.
Those two rules are what let saving stop waiting without letting a refresh undo it, and the second also fixes a data-loss bug the app has today.
One small indicator above the bottom bar shows what the engine is doing, in place of three per-list banners.

No backend change is needed.
The server cannot say what changed, so the pull takes everything and compares; the cursor table this adds is where an `updatedSince` value goes once the server offers one.

## Context

Saving a loan on slow wifi freezes the screen until the server answers, although the loan was safe on the phone a moment after the tap.
Typing a search, changing a filter and changing it back costs three requests for data the phone already holds, and opening home costs four more, every time.
[ARCHITECTURE.md](../ARCHITECTURE.md) describes the engine as it stands.

## How it works today

### Saving waits for the whole outbox

| Step | What happens | Where |
| --- | --- | --- |
| 1 | The bloc shows a full-screen `LoadingOverlay` | `loaner_bloc.dart:252` |
| 2 | The repository writes the row as `pending` and queues a job | `loaner_repository_impl.dart:87-88` |
| 3 | If `isOnline`, `_settle` awaits `SyncEngine.drain()` | `loaner_repository_impl.dart:147-153` |
| 4 | The overlay hides | `loaner_bloc.dart:268` |

Step 3 sends every due job for every feature, one after another, each allowed 30 seconds (`api_service.dart:45`).
`isOnline` asks `connectivity_plus` whether a network is attached, not whether it reaches the internet, so on wifi without internet one save holds the overlay for 30 seconds per queued job.
Ten handlers work this way: create, edit and delete for loans, categories and shop items, and shop's multi-variant create.
Customer writes show no overlay but still await the drain.

### Lists fetch on every load

| Step | What happens | Where |
| --- | --- | --- |
| 1 | A search, filter, scroll or tab open sends `LoadLoaners` | `home_page.dart:68`, `loaner_view.dart:36`, filter sheets |
| 2 | The bloc switches the Drift watch to the new filters, and the list redraws from local rows | `loaner_bloc.dart`, `watchLoaners` |
| 3 | If online, the bloc also calls `RefreshLoanersUseCase`, one `GET /loans` page | `loaner_bloc.dart:185` |
| 4 | The page is written with `insertOrReplace`, every row marked `synced` | `LoanerDao.cacheServerLoaners` |

Shop items, categories and customers work the same way; income has its own pull and is out of scope.
Watch queries have no limit, so the list already shows every cached row; server paging only decides which rows reach the cache.
Reconnecting makes three blocs each drain and then fetch, and nothing reacts to the app resuming.

### A pull can overwrite an unsent edit

Step 4 does not check for queued work, in any of the four DAOs, and did not before the restructure either (`shop_service.dart` at `0a9508e` wrote pulls the same way).

The seller marks loan 38 paid while the push is still on the wire, and pulls to refresh:

| Time | Push | Pull | Loan 38 in Drift |
| --- | --- | --- | --- |
| 1 | — | — | paid, `pending`; job queued |
| 2 | reads the row, sends `PUT` | — | paid, `pending` |
| 3 | waiting | `GET` returns the server's copy, without the edit; `insertOrReplace` writes it | **unpaid**, `synced` |
| 4 | times out; the retry re-reads the row | — | unpaid |
| 5 | sends *unpaid*, succeeds | — | the edit is gone |

Nothing reports the loss.
A queued delete fares the same way: the pull writes `isDeleted: false` over it and the loan reappears.
Any failed or rejected push leaves the same opening; `79a15ee`'s `customerId` 400 was one.

### Sync feedback

Each of `loaner_view.dart`, `customer_page.dart` and `shop_tab.dart` shows its own `syncMessage` banner, set by its bloc from a connectivity check.
Nine of those messages are English literals in bloc code, so a Khmer-speaking seller reads English.
No list card shows a row's `syncStatus`, so a pending loan looks the same as a synced one.

## Goals

- Saving a loan, category, customer or shop item closes the form without waiting for the network, including on wifi without internet.
- Searching, filtering, scrolling and switching tabs send no request.
- Opening the app twice within the staleness window sends no list request the second time.
- An edit or delete that has not reached the server survives any pull, including one started while that edit is being pushed.
- A row deleted on the server disappears from the phone after the next full pull.
- The seller can see how many changes are waiting, and which ones the server refused and why.
- A job the server rejected is sent again once per app launch, not on every drain.

## Non-goals

- **No backend change.** Delta sync needs `updatedSince` and tombstones (records of rows deleted on the server); the cursor table leaves room for them.
- **Image upload stays online-only.** `UploadBloc` keeps its overlay; queueing files is its own design.
- **Sign-in and profile edits keep their overlay.** They are not outbox writes.
- **Income is not touched.** It pulls through `PullRemoteNotificationsUseCase` with its own 20-second floor, and it is off in production.
- **No UUID local ids.** Collisions stay a known gap; that is a schema change of its own.
- **No two-device conflict handling.** The last write to reach the server still wins.
- **No change-ping over FCM (Firebase push messages).** It needs the backend to send one.

## Approach

### A queued row belongs to the phone

A local row belongs to the phone while the outbox holds any job for its `localId` (the entity's id as text, `'${loaner.id}'` today).
A job leaves the outbox only after the server confirms it, so a push in flight still counts.
While a row belongs to the phone, a pull neither overwrites nor deletes it; rows with a negative id have never reached the server, so a pull never deletes them either.

Each DAO's `cacheServer*` becomes `reconcileServer*(rows, {required bool complete})`, one Drift transaction that:

1. reads the queued `localId`s for its entity type from `outboxEntries`;
2. upserts each server row as `synced`, skipping any that are queued;
3. when `complete` is true, deletes rows with a positive id that the server did not return and that are not queued.

Reading the queue inside the same transaction closes the window where an edit lands between the check and the write, because Drift runs transactions on one connection one at a time.
A pull that failed on any page passes `complete: false`, so a partial list never deletes anything.

This lands first and on its own: it fixes today's bug with no other change.

### One sync at a time

`SyncEngine` gains `requestSync()` and `pull({bool force = false, Set<SyncEntityType>? only})`, both run through one queue:

- a call while nothing runs starts the work;
- `requestSync()` while a push runs marks it dirty, and the push loops once more when it ends instead of starting a second one;
- `pull()` waits for any running push, drains first, then downloads, so the server holds this phone's writes before it is asked for the list.

A pull therefore never sees a half-finished push.
That covers creates too: between the server assigning id 50 and `reconcileCreated` swapping the phone's `-123` for it, no pull can run, so the loan is never shown twice.

`drain()` stays for tests and for the engine's own use.

### Saving returns after the local write

`_settle` in the four repositories stops awaiting the drain: it calls `requestSync()` without awaiting it and returns `Ok(local)`.
The list redraws on its own as the row moves from `pending` to `synced` or takes its server id, because it already watches Drift.

The ten `LoadingOverlay.show()` calls in the loan, category and shop-item handlers go.
The three that stay guard work that needs the network: sign-in (`auth_service.dart:208`), profile update (`profile_bloc.dart:32`) and image upload (`upload_bloc.dart:62`).
A save no longer reports a server error, because it no longer waits for one; refusals surface through the indicator below.

### The pull side of the engine

`jabhouy_sync` gains a port next to `FeatureSyncAdapter`, still pure Dart:

```dart
abstract interface class FeaturePullAdapter {
  SyncEntityType get entityType;

  /// Downloads every server row for this entity and reconciles it.
  Future<Result<void>> pullAll();
}
```

`pull()` walks the adapters parents first — category, customer, shop item, loan — pulls each one that is forced or stale, and records `lastPulledAt` for each that succeeded.
Each `pullAll` requests `limit=100` and follows `hasNext` until it is false; categories come back as one unpaged list.
Whether the server caps `limit` below 100 is unmeasured; following `hasNext` works either way.

The cursor lives in a new table in `jabhouy_core`, taking the schema from 7 to 8 with a `createTable` step:

| Column | Holds |
| --- | --- |
| `entityType` | primary key |
| `lastPulledAt` | when the last complete pull of this entity succeeded |
| `cursor` | nullable; unused until the server offers `updatedSince` |

The staleness window is 15 minutes.
One seller on usually one phone makes almost every change on this device, so the window only bounds how old another device's edits can look.

### Who starts a sync

`SyncCoordinator` in `lib/app/service/` starts background work:

| Moment | Call |
| --- | --- |
| After sign-in | `pull()` |
| `AppLifecycleState.resumed` | `pull()` |
| `connectivityStream` turns true | `pull()`, which drains first |
| App launch | makes rejected jobs due once, then `requestSync()` |

A save calls `requestSync()`; pull-to-refresh calls `pull(force: true, only: {that list's entity})` and keeps its spinner until the pull ends, including any push it waited for.

### What the blocs lose

`LoadLoaners`, `ShopGetItemsEvent`, `LoadCustomers` and `CategoryGetEvent` only change the Drift watch.
The online/offline branches, `_refreshLoaners` in the load path, the three `_onConnectivityChanged` handlers, scroll-to-bottom paging, and every `syncMessage` go.
`RefreshLoanersUseCase` exists to cache the customers embedded in a loans page; with customers pulled whole it has no job left and is deleted, and loaner's `logic/` folder goes with it unless something else needs one.

### The sync indicator

`SyncEngine` publishes `Stream<SyncActivity>`, and one widget in `jabhouy_ui` shows it as a pill above home's floating bottom bar, clear of the round action button:

| Engine state | Pill | Behaviour |
| --- | --- | --- |
| Idle, nothing queued | hidden | — |
| Pushing | "Syncing…" | appears only after 1 second, so a quick save does not flash it |
| Offline, jobs queued | "3 changes waiting" | stays while offline |
| Jobs rejected or retrying | "2 changes failed" | stays; a tap lists the rows and their `lastError` |
| A sync the seller started just ended | "Synced" | 1.5 seconds, then hides |

The 1-second and 1.5-second values are chosen, not measured.
Background pulls stay silent, because nobody is waiting on them.
The pill takes no taps except in the failed state, and its text lives in `jabhouy_l10n` in English and Khmer.

List cards for loans, customers and shop items gain a small icon for `pending` and `failed`, so the seller can tell a waiting row from a synced one at a glance.

### Rejected jobs

`_recordRejection` sets `nextAttemptAt` to the end of time instead of leaving it due.
At launch the coordinator makes every rejected job due once, so a client fix still reaches the server with the next build.
Re-enqueueing a row, which any edit does, already resets the schedule.

## Alternatives considered

**A freshness window on the existing fetches.** Cheapest, and it cuts most requests, but search results still depend on which pages happened to load, server deletes are never seen, and the overwrite bug stays.

**Search and filter on the server, cache per query.** Keeps the server's search semantics, but every new search is a request by definition, which is the complaint.

**Pull only the first page on each open.** Fewer bytes, but a partial list can never delete anything, so rows removed on the server stay forever.

**Keep awaiting the drain, with a shorter timeout.** Bounds the freeze but keeps it, and a save still waits on every other feature's queue.

**A bottom sheet or snackbar for sync state.** Covers the bottom bar or disappears before the seller reads it; the state that matters most, changes waiting while offline, has to stay visible.

## Risks and open questions

- **Deleting rows is the one irreversible step.** A bug in the rule removes a row the seller wrote. The tests below cover each case the rule names, and the flag below turns it off without a release.
- **A refusal is now noticed late.** A save that the server rejects closes the form and shows up as "failed" in the pill instead of an error on the spot. The pill's list and the row icon are what make that acceptable.
- **Full-pull cost is unmeasured.** The first pull logs `Pagination.total` and the page count per entity, so the real size is known after one run on the seller's phone.
- **Decision for you: the 15-minute window.** Shorter shows other-device edits sooner and costs more requests.

## Testing

| Case | Where |
| --- | --- |
| A queued edit survives a pull that returns the server's older copy | `test/loaner/loaner_repository_test.dart` |
| A queued delete is not revived by a pull | same |
| A complete pull deletes a synced row the server dropped; an incomplete one deletes nothing | same, and shop's and customer's repository tests |
| A negative-id row is never deleted | same |
| A save returns before the push ends; a push the transport holds open does not delay it | same, with a transport that waits on a `Completer` |
| `requestSync()` during a push runs one follow-up, not a second push | `packages/jabhouy_sync/test/`, under `dart test` |
| A pull waits for a running push, drains first, and walks parents first | same |
| The window holds, and `force` bypasses it | same |
| `SyncActivity` reports pushing, waiting and failed counts | same |
| A rejected job waits for the next launch | same |
| Search, filter and scroll call no API | bloc tests with `verifyNever` on the API mock |

What stays untested is the lifecycle wiring in `SyncCoordinator` and the pill's placement; both are checked by running the app.

## Rollout

1. Land the reconcile rule alone, with its tests. It changes no triggers and fixes the overwrite bug. **Done:** the skip half, in all four `cacheServer*` methods; the delete half needs a complete pull and lands with step 3.
2. Land the engine queue, `requestSync()`, `SyncActivity` and the rejected-job rule. Nothing calls them yet except the existing `drain()` paths. **Done;** `bootstrap()` releases rejected jobs at launch until `SyncCoordinator` exists.
3. Behind `Feature.backgroundSync` — on in development and staging, off in production — land non-blocking saves, the pull side with the cursor table (schema 8), `SyncCoordinator`, local-only list loads, the pill and the row icons. **Done:** non-blocking saves (`4899612`), the pull side (`df2e54e`), `SyncCoordinator` with local-only loads (`9f3e457`), and the pill and row icons. Two departures: the pill lives in `lib/app/widget/`, not `jabhouy_ui`, because it reads `SyncEngine` and `jabhouy_ui` has no reason to depend on `jabhouy_sync`; and row icons show whatever the flag, because `syncStatus` is true in both modes. `SyncCoordinator` also calls `SyncEngine.retryNow()` on reconnect, which this plan did not name: pushes that failed on wifi without internet would otherwise sit out up to 30 minutes of backoff.
4. Run a development build on the seller's phone for a few days; read the pull logs for row counts and any unexpected deletes. **Done:** tested by the seller before release.
5. Turn the flag on in `config/features/production.json` and release. **Done** in 1.0.21.
6. One release later, delete the old save and fetch paths, the banners, and the flag.

To roll back before step 6, set `FEATURE_BACKGROUND_SYNC` to `false` and rebuild.
The cursor table stays, unused; schema 8 needs no downgrade.

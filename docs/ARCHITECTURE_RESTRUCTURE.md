# Architecture restructure

**Status:** Draft
**Author:** Punlork
**Updated:** 2026-09-04

## Summary

Jabhouy moves from feature folders containing god-object services to layered features over a shared core, then extracts three packages in a pub workspace.
The offline sync logic — currently cloned into four services with no retry path — consolidates into one engine that generalizes the idempotency and coalescing patterns already working in the income feature.
Shop is layered first as the reference slice, and is the single feature promoted to its own package as a deliberate modularization experiment.

## Context

The app works, but its structure does not express what it does, and its sync layer loses writes.

`lib/` holds 145 Dart files and 19,961 lines excluding generated code and localizations, covered by 6 test files.
There are zero repositories, zero use cases, and zero DAOs: `find lib -iname '*repositor*' -o -iname '*usecase*' -o -iname '*dao*'` returns nothing.

For comparison, `lmsmobileapp` at 1,071 files and ~173k lines runs 49 repositories, 105 use cases, 45 DAOs, 318 test files, `schemaVersion` 106 with 5 committed schema snapshots and 30 schema/migration tests.
Its `CLAUDE.md` documents the layering rules this doc adopts.

## How it works today

Every feature is a bloc that holds a service, and the service does everything else.

```text
ShopBloc ──▶ ShopService ──┬──▶ AppDatabase          Drift — lib/app/service/database/app_database.dart
                           ├──▶ ApiService           http — lib/app/service/api_service.dart
                           └──▶ ConnectivityService
```

`lib/shop/service/shop_service.dart` is 380 lines that own Drift queries, HTTP calls, sync orchestration, and row-to-model mapping together.
There is no layer between the bloc and the database.

Writes are local-first.
`createShopItem` (`lib/shop/service/shop_service.dart:223`) mints a negative ID, inserts the row as pending, and drains immediately if the device is online:

```dart
final id = body.id == 0
    ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
    : body.id;
final localItem = body.copyWith(id: id, syncStatus: 1);

await _db.into(_db.shopItems).insert(
      ShopItemsCompanion.insert(/* … */, syncStatus: const Value(1)),
      mode: InsertMode.insertOrReplace,
    );

if (localOnly) {
  if (await _connectivityService.isOnline) {
    await syncPendingChanges();
```

Draining is `syncPendingChanges()`, the one function that decides everything about sync.
It exists four times, once per CRUD entity, and the four bodies are near-verbatim clones:

| File                                          | Line |
| --------------------------------------------- | ---- |
| `lib/shop/service/shop_service.dart`          | 80   |
| `lib/shop/service/category_service.dart`      | 30   |
| `lib/customer/services/customer_service.dart` | 34   |
| `lib/loaner/services/loaner_service.dart`     | 153  |

Each body is a select on `syncStatus = 1`, a sequential loop, and a `try`/`catch` that writes `2` on any failure:

```dart
Future<void> syncPendingChanges() async {
  if (!await _connectivityService.isOnline) return;

  final pendingItems = await (_db.select(_db.shopItems)
        ..where((t) => t.syncStatus.equals(1)))
      .get();

  for (final item in pendingItems) {
    try {
      ApiResponse<ShopItemModel?> response;
      if (item.isDeleted) {
        await deleteShopItem(model, localOnly: false);
        response = ApiResponse(success: true);   // result of the delete is ignored
      } else if (item.id < 0) {
        response = await createShopItem(model, localOnly: false);
      } else {
        response = await updateShopItem(model, localOnly: false);
      }

      if (!response.success) {
        await /* … */ .write(const ShopItemsCompanion(syncStatus: Value(2)));
      }
    } catch (_) {
      await /* … */ .write(const ShopItemsCompanion(syncStatus: Value(2)));
    }
  }
}
```

That is the whole sync layer: roughly forty lines, four times over.
`syncStatus` is an untyped `int` on every table — `0` synced, `1` pending, `2` error — and it is both the queue and the only record of what happened.

### Seven ways that loses a write

Each defect is a property of those forty lines, so each exists four times.

**A sale recorded on flaky wifi never reaches the server, and nothing ever tries again.**
Nothing in the app queries for `syncStatus = 2`.
There is no attempt counter, no backoff, and no dead-letter path anywhere in `lib`; grep for `retryCount|attempt|backoff|maxRetries` finds one unrelated match.
A write that fails once is marked `2` and is finished.

**A product the seller deleted comes back on the next pull.**
The delete is reported as a success no matter what the server said, so the row is marked synced and the queue forgets it.
In all four services the delete branch discards its result:

```dart
if (item.isDeleted) {
  await deleteCategory(model, localOnly: false);
  response = ApiResponse(success: true);   // result of the delete is ignored
}
```

**Two products added twenty minutes apart collapse into one, and the first vanishes without an error.**
Local IDs come from `-(DateTime.now().millisecondsSinceEpoch % 1000000)` (`shop_service.dart:228`, plus three siblings).
That expression wraps every 1,000,000 ms — about 16.7 minutes — so two offline rows created in different windows can take the same ID.
The insert uses `InsertMode.insertOrReplace` (`shop_service.dart:245`), which is why the collision overwrites the earlier row instead of raising.

**Items the seller filed under a brand-new offline category are rejected on reconnect.**
`ShopItems.categoryId` references `Categories.id`, but each service drains its own table independently, so an item can push before the category it points at.
Ordering across tables is accidental.

**Killing the app mid-sync deletes the product from the phone entirely.**
On create, the local row is deleted and the server row inserted as two separate statements.
A crash between them loses the row from both sides.

**When any of the above happens, the logs cannot say which.**
`lib/` contains 12 `catch (_)` blocks, most of them in these sync paths, each collapsing a distinct failure into the same `syncStatus = 2`.

**When two devices disagree, the one with the faster clock wins.**
Grep for `conflict|lastWriteWins|serverWins` finds nothing.
`updatedAt` is written from the device clock, so clock skew decides outcomes.
`Categories` has no `createdAt` or `updatedAt` at all, leaving category conflicts with no timestamp to compare.

### Income already solves this, and is the model to copy

`lib/income/services/firebase_income_sync_service.dart` is the one sync path that does not lose writes, and it is the only one worth generalizing.

`BankNotifications` carries a unique `fingerprint` (`app_database.dart`), so the same notification arriving twice is admitted once.
`syncNotification` coalesces concurrent syncs of one fingerprint through `_inFlightNotificationSyncs`.
`_rememberSyncedFingerprint` keeps an LRU-bounded set of 200 recent keys.
Every branch writes a structured entry through `_diagnostics.log`.
It is gated by device role and retries its backlog on connectivity change.

### Schema discipline is absent

`schemaVersion` is 5 (`lib/app/service/database/app_database.dart:99`) with an `onUpgrade`-only `MigrationStrategy`, no schema snapshots, no migration tests, and no declared index — including none on `syncStatus`, which every sync query filters on.

## Goals

- No `syncStatus` integer literals in feature code; sync state is a typed enum.
- A write that fails is retried with backoff and is visible in diagnostics; no failure reaches a silent terminal state.
- Local IDs cannot collide.
- No bloc references a Drift table or `ApiService`; a bloc depends on a repository, or on a use case where its feature has one.
- Shop, loaner, and income each have repository tests covering success and failure; loaner and income also have use case tests.
- `flutter analyze` reports zero errors, including in `test/`.
- `jabhouy_core` and `jabhouy_sync` build with no dependency on the app package.
- `jabhouy_sync` has no Flutter dependency and its tests run under `dart test`.

## Non-goals

- **Customer, auth, profile, and home keep their current shape.** Shop, loaner, and income are the app's three real features; the rest stay behind their existing services. Customer gains a DAO only where loaner needs one, because `Loaners.customerId` references `Customers.id`.
- **No feature package beyond `jabhouy_shop`.** One is the experiment. Whether the others follow is decided after it, not before.
- **No merge engine, CRDTs, or operational transforms.** One seller, one shop, usually one device: the conflict space does not justify them. Server-timestamp last-write-wins is the chosen policy.
- **No migration of existing local data.** The app is in development with no external users, so schema changes may recreate the database.
- **No database encryption.** `lmsmobileapp` uses SQLCipher because it holds customer lending data. Jabhouy does not need it yet.
- **No UI or visual redesign.** Widgets move between folders; they do not change behavior.

## Approach

Layering comes first and packaging second: features gain a `ui`/`data` split over a shared core with use cases only where they are earned, the four `syncPendingChanges()` clones collapse into one outbox-driven engine, and only then do `core` and `sync` graduate into packages.
The three decisions worth arguing about are all here — an outbox table instead of a status column, clean architecture inside `jabhouy_sync` only, and one feature package rather than eight.

### Target layout

The repository becomes a pub workspace. Dart is 3.13.1, so `workspace:` resolution is available natively and melos is not needed.

```text
jabhouy/
├── pubspec.yaml            # workspace root
├── lib/                    # app shell: features in folders
└── packages/
    ├── jabhouy_core/       # Result, AppException, SyncStatus, network, db primitives
    ├── jabhouy_sync/       # sync engine — pure Dart, no Flutter
    └── jabhouy_shop/       # one feature package (experiment)
```

### Layering rules

Two layers in every feature, and a third only where it earns its place.
This follows [Flutter's published architecture guidance](https://docs.flutter.dev/app-architecture/guide), which recommends a `ui` and a `data` layer and calls the domain layer "optional because not all applications or features within an application have these requirements".

```text
features/<name>/
├── ui/       screens, widgets, bloc
├── data/     repository, plus db/ (Drift DAO) and api/ (HTTP) sources
└── logic/    use cases — present only where earned
```

`logic/` is Flutter's optional domain layer under a name that says what is inside it.
`data` answers where a value came from and `logic` answers which rule applies to it.
`data` and `domain` are the pair that reads ambiguously — both sound like they hold the data — which is the reason for the rename.

Flow is `ui` → `logic` (where present) → repository → DAO or API.

- `logic/` imports no Flutter and no Drift.
- `ui/` talks to a repository, or to a use case where one exists, and never to a Drift table or `ApiService`.
- Where `logic/` is absent the repository is the seam, and it is still an interface with a test double behind it.

A feature earns `logic/` when its behavior meets one of the three conditions Flutter names: the logic merges data from multiple repositories, is exceedingly complex, or is reused by more than one bloc.

| Feature                        | Layers                                      | Condition met                                                                                                                              |
| ------------------------------ | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `jabhouy_sync`                 | `logic/` + ports and adapters, pure Dart    | All three: it merges the outbox with every entity table, owns backoff, dependency ordering and conflict resolution, and is driven by the shop, loaner, customer and income blocs |
| `loaner`                       | `ui/` `data/` `logic/`                      | Merges repositories — `Loaners.customerId` references `Customers.id`                                                                       |
| `income`                       | `ui/` `data/` `logic/`                      | Complexity — fingerprint dedup, notification parsing, main-device gating                                                                   |
| `shop`, `category`, `customer` | `ui/` `data/`                               | None today. Shop graduates if the default/customer/seller price rule turns out to be shared with loaner                                    |
| `auth`, `profile`, `home`, settings | `ui/` `data/`                          | None                                                                                                                                       |

That is roughly a dozen use cases rather than one per operation.
The five CRUD services expose 62 public methods between them, so a use case each would give this 20k-line project a higher use-case density than the 173k-line codebase such a rule would have come from.

### Core primitives

Four replacements in `jabhouy_core`, each removing a defect named above:

| Current                                         | Replacement                                                                             |
| ----------------------------------------------- | --------------------------------------------------------------------------------------- |
| `ApiResponse{success: bool, data: T?}`          | sealed `Result<T>` with `Ok(value)` and `Err(AppException)` variants, removing `!` at call sites |
| `int syncStatus` (`0`/`1`/`2`)                  | `enum SyncStatus { synced, pending, failed }` with a Drift converter                    |
| `-(millis % 1000000)` local IDs                 | UUID v4 `localId` column; server ID stays nullable until reconciliation                 |
| `BaseService.post(BuildContext?, showSnackBar)` | transport returns `Result`; the `ui` layer decides what to show                          |

`ApiService` currently constructs URLs with `Uri.https(_baseUrl, ...)` and normalizes the authority in `_normalizeAuthority`.
That normalization moves into `jabhouy_core` with the transport.

### Sync engine

`jabhouy_sync` generalizes the income implementation rather than introducing a new design, because income is the only sync path in the app that does not lose writes.

The engine introduces one table and six names. They are defined here before they are used:

| Name               | What it holds                                                   | Why this name                                                                 |
| ------------------ | --------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `OutboxEntries`    | One row per write waiting to reach the server                   | The queue is the new concept; `syncStatus` described a row, this describes a job |
| `entityType`       | `shopItem`, `category`, `customer`, `loaner`, `bankNotification` | Matches the model class names already in `lib/`                               |
| `entityLocalId`    | The UUID of the local row this job is about                     | `localId` is the new primary key name; the prefix says which table            |
| `fingerprint`      | The value that makes replaying a job safe                       | Keeps the name `BankNotifications` already uses — 104 occurrences in `lib/`    |
| `attemptCount`     | How many pushes this job has survived; drives backoff           | —                                                                             |
| `nextAttemptAt`    | The earliest time the drain loop may pick this job up again     | —                                                                             |
| `dependsOnLocalId` | The `entityLocalId` this job must wait for                      | Names the relationship, not the FK-ordering algorithm                         |

`fingerprint` is deliberately not called `idempotencyKey`.
`idempotencyKey` is the more precise general term, but the codebase has said `fingerprint` 104 times and a reviewer reading the outbox should recognize the concept they already know rather than meet a new one.

`OutboxEntries` replaces the per-row `syncStatus` flag as the queue:

| Column             | Purpose                                                          |
| ------------------ | ---------------------------------------------------------------- |
| `id`               | autoincrement                                                    |
| `entityType`       | which table the job belongs to                                   |
| `entityLocalId`    | UUID of the local row                                            |
| `operation`        | `create`, `update`, `delete`                                     |
| `fingerprint`      | generalizes `BankNotifications.fingerprint`                      |
| `attemptCount`     | drives backoff; absent today                                     |
| `nextAttemptAt`    | exponential backoff schedule                                     |
| `lastError`        | replaces the 12 `catch (_)` blocks                               |
| `dependsOnLocalId` | orders `ShopItems` after its `Categories` row                    |

Behavior carried over from `firebase_income_sync_service.dart`:

- Concurrent pushes of one `fingerprint` coalesce onto a single future, as `_inFlightNotificationSyncs` does now.
- Recently-succeeded fingerprints are held in a bounded LRU, as `_rememberSyncedFingerprint` does with 200 entries.
- Every transition writes a structured diagnostic entry.

Behavior that is new:

- `attemptCount` and `nextAttemptAt` give exponential backoff, so `failed` becomes retryable rather than terminal.
- ID reconciliation runs inside one Drift transaction, replacing delete-then-insert.
- Delete results are checked instead of assumed, fixing the hardcoded `ApiResponse(success: true)`.
- Entries with `dependsOnLocalId` wait for their dependency to reconcile.
- Conflicts resolve on server timestamps. `Categories` gains `createdAt` and `updatedAt` so it can participate.

An index on `(entityType, nextAttemptAt)` supports the drain query.

### Phasing

Layer before extracting: packaging first would mean refactoring across package boundaries.

| Phase | Work                                                                                                                                         | Done when                            |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| 0     | Rename package `my_app` → `jabhouy`; fix the 5 errors in `test/income_service_test.dart`; unify `service/`↔`services/` and `views/`↔`pages/` | `flutter analyze` clean, tests green |
| 1     | `lib/core/` as a folder, written package-shaped: no app imports, no Flutter in `logic/`                                                      | Core primitives in use               |
| 2     | Shop slice: `ShopDao`, repository interface and implementation, bloc on the repository — shop earns no `logic/`                              | Shop tests pass                      |
| 3     | Sync engine: outbox table, drain loop, four `syncPendingChanges()` deleted                                                                   | Scenario tests pass                  |
| 4     | Loaner and income slices layered, including the `logic/` use cases each one earns                                                            | Their tests pass                     |
| 5     | Promote `core/` and sync to `packages/`; extract `jabhouy_shop`                                                                              | Workspace resolves                   |
| 6     | bloc 8→9, go_router 14→18, using `lmsmobileapp` as the reference migration                                                                   | App runs                             |
| 7     | Showcase `ARCHITECTURE.md`, `CLAUDE.md`, README rewrite                                                                                      | —                                    |

Each phase is a separate commit and leaves the app runnable.

## Alternatives considered

**Folder-based layering with no packages.** This is what `lmsmobileapp` does at 8.6× the size, which is the strongest argument for it: package boundaries are not required to get clean layering. Rejected only for `core` and `sync`, where a package makes the "no app imports" and "no Flutter" rules compile-time errors instead of review comments. Accepted for the remaining features, which stay folders.

**A package per feature.** Eight packages at 20k lines costs eight pubspecs, cross-package `build_runner` runs, and generated code crossing boundaries, without changing what the code does. One feature package answers the question at a fraction of the cost.

**Porting `lmsmobileapp`'s Clean Architecture wholesale.** Its `CLAUDE.md` mandates `data`/`domain`/`presentation` in every feature plus "one use case per financial operation", which is the right call for auditable lending maintained by a team. Two things rule it out here.

The first is that Flutter's own guidance argues against it: "a good approach is to add use-cases only when needed", and it warns specifically against a use case for every data access. The second is that lms does not follow its own rule:

| Feature                   | `data` | `domain` | `presentation` | use cases |
| ------------------------- | ------ | -------- | -------------- | --------- |
| `customer`, `prospect`    | yes    | yes      | yes            | 16, 18    |
| `auth`, `calendar`        | yes    | yes      | yes            | 0         |
| `loan`                    | —      | —        | —              | 38        |
| `loan_disbursement`       | yes    | yes      | yes            | 7         |
| `master_data`             | yes    | yes      | —              | 2         |
| `tutorial`                | —      | —        | yes            | 0         |
| `home`, `setting`, `splash` | —    | —        | —              | 0         |

`auth` and `calendar` carry all three layers and zero use cases, so they break the "never call a repository from presentation" rule the same document sets.
`loan` carries 38 use cases and none of the three folders.
The 13 features run at least four different shapes between them, which is the same tiered outcome this doc adopts — lms simply reaches it by drift rather than by a stated rule. Citing it as "one standard" would document an aspiration instead of the code.

**Clean architecture in every Jabhouy feature.** Rejected for the same reason at smaller scale: a settings screen reading three booleans does not get safer for having an entity, a repository interface, and a use case. `jabhouy_sync` keeps the full layering because it must compile without Flutter and must be testable under `dart test`, which the layering enforces mechanically.

**Melos.** Melos predates pub workspaces and still adds value for script running and coordinated versioning. Neither is needed yet: the workspace has one publishable package and no release automation. `workspace:` covers resolution with no bootstrap step.

**Keeping `syncStatus` and adding a retry counter.** Cheaper than an outbox table, but it cannot express operation ordering, cannot distinguish create from update after the fact, and offers nowhere to put `dependsOnLocalId`. The FK ordering defect stays unfixable.

**CRDTs or a merge engine.** Correct for concurrent editors. Jabhouy has one seller per shop, so it would add a large amount of machinery to resolve conflicts that mostly do not occur.

## Risks and open questions

- **Phase 0 touches every file.** The `my_app` → `jabhouy` rename rewrites imports across 145 files. It is mechanical and diff-reviewable, but it must land alone, not mixed with logic changes.
- **Phase 6 is the largest behavioral risk.** go_router 14→18 is four majors against `lib/app/routes/app_routes.dart`, which uses `CustomTransitionPage`, a `redirect` reading `AuthBloc`, and a `GlobalContext.currentContext` assignment inside `pageBuilder`. `lmsmobileapp` already runs go_router 17, so a working reference exists.
- **Cross-package Drift codegen is the likeliest source of lost time in Phase 5.** If tables live in `jabhouy_core` and DAOs in features, generated code crosses a package boundary. Decide where tables live before extracting.
- **`sendTestNotification` is the production upload path** for real notifications, despite its name. Renaming it is in scope for Phase 4; it currently obscures which code path matters.
- **`dio: ^5.8.0+1` is declared and never imported.** `grep "package:dio" lib/` returns nothing. Open: adopt Dio with interceptors as `lmsmobileapp` does, or drop the dependency and keep `http`. Deciding this changes the Phase 1 transport work.
- **Open: does `OutboxEntries` supersede `BankNotifications.syncStatus`,** or does income keep its own column and register with the engine through an adapter? The first is cleaner; the second is a smaller Phase 4.
- **Open: does shop's price rule belong in `logic/`?** Shop earns no `logic/` folder under the three conditions today. If the loaner flow reuses the default/customer/seller price selection, that makes it "reused by more than one bloc" and shop graduates. Check when Phase 4 layers loaner, not before.

## Testing

Current state: 6 test files for ~20k lines, and `test/income_service_test.dart` has 5 compile errors from stale `IncomeService` constructor arguments, so the suite does not run.
`flutter analyze` reports 24 issues — those 5 errors, 2 warnings in `lib/home/`, and 17 infos — and nothing in `lib/` errors.
Phase 0 fixes the test first, because new breakage cannot be distinguished from old until it does.

Conventions: tests mirror `lib/`, `mocktail` for mocking, `bloc_test` for blocs.

| Layer        | Approach                                                                                  |
| ------------ | ----------------------------------------------------------------------------------------- |
| Repositories | Against `AppDatabase.forTesting` with an in-memory database; DAOs are not tested directly |
| Use cases    | Success and failure path each, in loaner and income only                                   |
| Blocs        | `bloc_test` on emit sequences                                                              |
| Sync engine  | Pure Dart under `dart test`, no Flutter binding                                            |
| Migrations   | Committed schema snapshots via `drift_dev schema dump`, then generated migration tests    |

Sync tests are named as scenarios, so the suite doubles as the description of the engine:

- create offline, reconnect, row reconciles to its server ID
- push fails with 500, entry retries with backoff, succeeds on attempt 3
- item pushes before its offline-created category, engine orders them
- process is killed mid-reconciliation, row survives restart
- same notification arrives twice, fingerprint admits one
- delete fails remotely, entry stays queued instead of being marked synced
- two rows created 20 minutes apart keep distinct `localId`s

Each scenario maps to one of the seven defects above, so a regression re-opens a named failure rather than an anonymous test.

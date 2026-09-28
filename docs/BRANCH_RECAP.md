# Branch recap: `refactor/architecture-restructure`

**Updated:** 2026-09-28 · 58 commits over `main` · 273 files, +19,802 / −7,872 lines

## Summary

The branch turns the app from feature folders with service god-objects into a pub workspace — the app shell plus six packages — with one offline sync engine behind every feature.
Along the way it fixes eleven bugs, four of which lost or corrupted the seller's data, and adds build-time feature flags, Melos, CI that tests, and a rebuilt shop form and listing.
Background sync — saves that never wait for the server, lists that never fetch on a tap — is built, tested on the seller's phone, and on in every flavor as of 1.0.21.

| | `main` | This branch |
| --- | --- | --- |
| Packages | 0 | 6 (`core`, `sync`, `net`, `ui`, `l10n`, `shop`) |
| Test files | 6, and the suite did not compile (5 errors) | 32 |
| Tests passing | 0 | 165 (app 70, shop 42, core 24, sync 29) |
| Analyzer | 24 issues, 5 errors | 3 issues, 0 errors |
| CI | release build only | analyze + every suite, and release waits for it |
| Sync retry | none: one failure was final | backoff, dependency order, kept reasons |

## 1. The restructure (phases 0–7)

The plan and its reasoning are in [ARCHITECTURE_RESTRUCTURE.md](ARCHITECTURE_RESTRUCTURE.md); the result is described in [ARCHITECTURE.md](../ARCHITECTURE.md).

| Phase | What | Commits |
| --- | --- | --- |
| 0 | Package renamed `my_app` → `jabhouy`; the test suite compiles again | `0a9508e` |
| 1 | Drift schema into `jabhouy_core`, kept pure Dart; `syncStatus` int → `SyncStatus` enum | `8c30b1f` `caba4c5` `c391ebb` |
| 2 | Shop layered over a repository, `ui/` split out | `574109e` `0768f99` |
| 3 | Outbox table and `jabhouy_sync` engine; shop, category, customer and loan drain through it, retiring four copies of `syncPendingChanges()` | `0dd2c1c` `28a89ac` `071cbe1` `158c3ac` `82ac9e5` `c7e04a4` |
| — | `Result<T>` / `AppException` in core; `logic/` layering enforced by a test | `d3240be` `75d9403` `13fe4d2` |
| 4 | Income layered and on the engine | `d202623` `6503310` |
| 5 | `jabhouy_ui`, `jabhouy_net`, `jabhouy_l10n`, then `jabhouy_shop` extracted; a test fails if any package imports the app | `22c5714` `a3c7367` `1550cfe` |
| 6 | bloc 8 → 9, go_router 14 → 18, with no source changes needed | `d886a78` `d7b9fdc` |
| 7 | `ARCHITECTURE.md`, `CLAUDE.md`, README; copilot instructions point at `CLAUDE.md` | `18f7ebe` |

## 2. Bugs fixed

Data loss first.

| Bug | What the seller saw | Commit |
| --- | --- | --- |
| A refresh wrote the server's copy over an edit that had not synced, and the queued job then sent that older copy | An edit — or a delete — silently undone | `a247225` |
| `customerId` read only as a flat field; the API nests it, so every pull and push nulled it | Loan edits rejected with a 400 | `79a15ee` |
| Income marked never-uploaded notifications as synced | Notifications that never reached the server | `6bf59b2` |
| Prices through `int.tryParse`: `1,500`, `1500.5`, `១៥០០` saved as no price | Items saved without a price, no error | `094aa51` |
| A loan's `createdAt` sent as a timestamp; the server wants a date | Loan edits rejected with a 400 | `0f2f3f1` |
| A deleted category still set as the filter threw in the dropdown | Crash: "Bad state: No element" | `48d1546` |
| A second `initialize()` returned before the first finished | Diagnostics or tracking read before they loaded | `7aa509e` |
| Spamming pull-to-refresh queued a full download per swipe | Requests piling up | `1a9789f` |
| A rejected job was re-sent on every drain | One wasted request per save or refresh, forever | `f21f724` |
| The list card showed `$400.00 / unit` for a riel price | Wrong currency | `637bd3e` |
| iOS kept the template's name | "My App" on the home screen | `bca736a` |

Most predate the restructure — the refresh overwrite, the income sync, `createdAt` and `customerId` among them; building and tracing the new engine is what surfaced them.

## 3. Offline sync

Plan and details: [OFFLINE_SYNC.md](OFFLINE_SYNC.md). Behind `Feature.backgroundSync`.

- **The engine** (`jabhouy_sync`) pushes an outbox with exponential backoff (10 s doubling to 30 min), dependency order (an item waits for its offline category), and a kept reason per failure. Rejected jobs park until the next launch, so a fixed build still sends them.
- **Saves return at once** (`4899612`): the row is written, the push runs in the background, and ten loading overlays are gone.
- **Lists never fetch on a tap** (`9f3e457`): search, filter and scroll read Drift. `SyncCoordinator` pulls after sign-in, on resume and on reconnect; each list downloads at most once per 15 minutes, and pull-to-refresh forces one.
- **A pull can delete safely** (`df2e54e`): only when the list is provably complete (no next page *and* the count matches the server's total), the row has a positive id, and it has no queued job. Pushes and pulls share one lock so a create landing mid-pull cannot be deleted. Schema 7 → 8 adds `SyncCursors`.
- **The seller sees it** (`f21c543`): a pill above the bottom bar — "N changes waiting" offline, "N changes failed" with the server's reason a tap away, "Syncing…" only past one second — and a mark on each unsynced row.

## 4. Feature flags

`6ac5778`. `FeatureFlags` in core reads `config/features/<flavor>.json` at build time; a missing key is off, and Gradle reads the same file for the Android manifest.

| Flag | development | staging | production |
| --- | --- | --- | --- |
| `FEATURE_INCOME` | on | on | off |
| `FEATURE_BACKGROUND_SYNC` | on | on | on, from 1.0.21 |

Income off hides its tab, device-role card and diagnostics, never starts capture, and leaves the Android notification listener out of the manifest — Google Play blocked 1.0.21 while it was only disabled.

## 5. Shop form and listing

- **Form** (`094aa51`): labels above fields, customer price on its own row, variant cards that collapse on create without escaping validation, a Single/Pack toggle, and "Cost Price" in place of "Default Price (per unit)".
- **Listing** (`637bd3e`): product name, then the variant label with its pack size, one grouped price (`40,000 ៛`), the category; a letter tile instead of a full-size logo. About seven cards per screen, up from four, with every overflow case tested.

## 6. Tooling

- **Melos** (`f1e635c`): `melos run analyze | test | gen | run:dev | build:prod`, running `dart test` and `flutter test` where each belongs.
- **CI**: a check job analyzes and runs every suite; the release job needs it.
- **copyWith** generated for 13 classes (`c29881c`); its null semantics are pinned by a test.
- **Dependencies** (`28c9477`): nine removed from the app — three used nowhere, six only by packages that already declare them — and the rest grouped by category.

## Not yet verified

- **Background sync on a device** was tried by the seller before release; long-running use in production has not happened yet.
- **The 7 → 8 migration on real data.** Tested on a hand-built schema-7 file, not on the seller's phone.
- **The new CI job.** It runs for the first time on the pull request.
- **Khmer wording** of the new strings (pill, row tooltips, form labels) wants a native reading.

## Open items

- **Rolling back background sync** is `FEATURE_BACKGROUND_SYNC: false` in `production.json` and a new release; schema 8 needs no downgrade.
- **Sign-out leaves the outbox.** `clearUserData()` clears the tables but not queued jobs, so one account's unsent writes could push under the next.
- **Local ids can collide:** offline ids are `-(millis % 1000000)`, which repeats every 16.7 minutes; the UUID `localId` is not built.
- **Two-device conflicts** resolve last-write-wins by timestamp, with clock skew unhandled.
- **No routing tests**, and Patrol commands do not pass the feature-flag file.
- **The flag-off path is now dead code in every flavor**: the old per-load fetches and banners. Plan step 6 deletes them one release after this, with the flag.

## Where to read more

- [ARCHITECTURE.md](../ARCHITECTURE.md) — the system as it stands
- [ARCHITECTURE_RESTRUCTURE.md](ARCHITECTURE_RESTRUCTURE.md) — why it took this shape
- [OFFLINE_SYNC.md](OFFLINE_SYNC.md) and [SHOP_ITEM_FORM.md](SHOP_ITEM_FORM.md) — the two plans built on this branch
- [CLAUDE.md](../CLAUDE.md) — commands and rules for working in the repo

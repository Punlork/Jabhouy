# Handoff: build the next redesign issues (Phase 3 shop → 3a find-first)

## Goal
Keep building the shop-app redesign issue by issue, offline-first: plan → user approves → test-first build → render check → gated commit → push to `dev`. The plan, its body and decisions 1–60 (bottom of the file, they override the body): `.scratch/redesign/plan.md`. Design canvas: https://claude.ai/artifact/7yB2Q6kx5udyawUJUPNZc2 (read with the Artifact tool, `project/<Screen>.dc.html`; index in `project/canvas.json`).

## State
- **Done:** issues 01–10, 12–15, 17, 19 (`.scratch/redesign/issues/`, each has a `## Comments` note on what was built and left out). Issue 16 half: category picker sheet + create-category in the item form.
- **Not started, in order:** 16b Categories & units screen → 20 ranked search → 21 recently viewed → 22 barcode scan → 23 Home find-first → 18 sign-in redesign → 11 sync `/changes` (blocked on Sokheng's API). 24 photo dropped for now. Then Phase 4 (Credit).
- **In progress:** nothing; working tree clean.

## Decisions made
All in `plan.md` decisions 41–60 (this session) — read them before building. The ones that shape the next issues:
- 25/53: categories have one per item; nothing is deleted, units only added or hidden.
- 42: search runs on the phone — normalise, rank exact → starts-with → nickname → contains → one-typo (4+ chars).
- 44/47: `FEATURE_BARCODE_SCAN` build-time flag, `mobile_scanner`.
- 46: recently viewed lives in the local `recent_item` table (schema 10, already created).
- 59/60: labels `ដប` / `កេះ (12)`; every sheet opens through `showAppSheet` + `AppSheet` (jabhouy_ui).
- The user drives the app and checks screens on a phone; Khmer wording not in the plan's §4 is checked with them (memory notes cover both).

## Tried and failed
- A chained `analyze; test; git commit` committed red work once (`fa17f95`, fixed `fddfa24`). Commit only inside `if` on "3 issues found" and no "failed".
- `watch…().first` on a Drift stream hangs widget tests (fake clock) → one-time reads use plain queries.
- `dart format <folder>` rewraps untouched files → format only edited files.
- Bulk-replacing a Khmer word broke a shared key's other use (`addItem` on the customer page) → grep every `l10n.<key>` use first.
- Rows mixing Khmer and Latin text look off when centred → `CrossAxisAlignment.baseline`.

## Verified / not verified
- Verified on every commit: `fvm dart run melos run analyze` = 3 issues (baseline), `fvm dart run melos run test` all green (core 41, sync 29, l10n 4, ui 81, shop 122, app 99). Screens rendered with the real font (golden into the scratchpad, temp test deleted) and checked by the user on their phone.
- Not verified: anything against the real API; the Telegram CI build/send (`.github/workflows/dev-telegram.yaml`, manual-only, secrets set; first run cancelled before sending); an iOS build after removing the staging flavor.

## Git
Branch `dev`, clean, pushed. Last commit: `docs: handoff for redesign Phase 3 …` (after `8d67771`).

## Open questions
- Categories & units: no canvas screen exists — the plan below needs the user's approval.
- Issue 22: the unknown-barcode screen (attach to an item / create) isn't on the canvas; decide before building the scan flow.
- `plan.md` §9 (starter categories, default rate, editor vs viewer) is the shop families' call.

## Next step
Post this plan for issue 16b and wait for approval, then build test-first:
- Settings › ហាង gets `ប្រភេទ និងឯកតា` (with count) → a page listing categories in order; hidden ones dimmed with a tag; drag handle to reorder; `+ បង្កើតប្រភេទថ្មី`.
- Tap a category → `showAppSheet` with name (rename), hide toggle, units as chips (tap to hide/show, `+ ឯកតា`), fixed `រក្សាទុក`.
- Owner and editor edit; viewer read-only. New repository call: reorder rewrites every `sortOrder`. `ItemRepository.saveCategory` already merges units without removing any.
- Tests: reorder persists; rename/hide reach Home chips and the picker; a new unit appears in the form's chips; a hidden unit drops out; viewer can't edit.

## Pointers
- Issues: `.scratch/redesign/issues/16-categories-units.md`, `20`–`23`; tracker rules `docs/agents/issue-tracker.md`
- Architecture rules: `CLAUDE.md`, `ARCHITECTURE.md`
- Code: `packages/jabhouy_shop/lib/src/{data,models,ui}/`, `packages/jabhouy_ui/lib/src/widget/{app_sheet,chips,money_input}.dart`, `lib/settings/ui/settings_page.dart`, `lib/app/routes/app_routes.dart` (+ `auth_redirect.dart` allowlist for new routes)
- API contract: https://github.com/sokhengpory/jabhouy-api/issues/2
- Previous handoff: `.scratch/handoffs/2026-10-16-redesign-phase-3.md`

## Suggested skills
- `ponytail` — smallest complete change for each issue.
- `tdd` — repository, cubit and search logic test-first.
- `verification-before-completion` — before claiming an issue done or committing.
- `domain-modeling` — if a new term appears (update `GLOSSARY.md`).

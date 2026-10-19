# Handoff: shop redesign, Phase 3 shop screens done; categories next

## Goal
Implement the shop-app redesign (Shop price list + Credit) offline-first, with Sokheng building the backend from the contract in jabhouy-api #2. Plan and every decision: `.scratch/redesign/plan.md` — decisions 1–60 at its bottom override its body; the "find-first" update (decisions 41–49) is the latest body change. The design canvas is https://claude.ai/artifact/7yB2Q6kx5udyawUJUPNZc2 (read files with the Artifact tool, `project/<Screen>.dc.html`).

## State (branch `dev`, everything committed and pushed, last `8d67771`)
- **Done this session** (38 commits): issues 13 (Home), 14 (details sheet), 15 (item form), 17 (shop settings + Settings restyle), 19 (schema 10: nicknames, barcode, recent_item); half of 16 (category picker sheet + create category in the form).
- **Open, in suggested order:** 16b Categories & units screen (plan below, not yet approved) → 20 ranked search → 21 recently viewed → 22 barcode scan (unknown-barcode screen undecided) → 23 Home find-first → 18 sign-in → 11 sync `/changes` (needs Sokheng's API). 24 photo is dropped for now.
- Phase 4 (Credit) after that.

## Next step
Post the Categories & units plan (below) and wait for approval, then build test-first:
- Page from Settings › ហាង › `ប្រភេទ និងឯកតា` (with count): categories in order, hidden ones dimmed with a tag, drag handle to reorder, `+ បង្កើតប្រភេទថ្មី`.
- Tap a category → `showAppSheet` with name (rename), hide toggle, units as chips (tap to hide/show, `+ ឯកតា`), fixed `រក្សាទុក`. Nothing is deleted (decision 25; units only added or hidden).
- Owner and editor edit; viewer read-only. New: reorder rewrites every `sortOrder`.
- No canvas screen exists for it; build from these patterns.

## Decisions made this session (all in plan.md)
41 barcode unique on the phone only · 42 search ranking + 1 typo for 4+ chars · 43 category chips pinned on scroll · 44 build-time flags `FEATURE_BARCODE_SCAN`, `FEATURE_VOICE_INPUT` · 45 schema 10 (drop moves to 11) · 46 recent_item local · 47 `mobile_scanner` · 48 phase order · 49 duplicate name warns · 50 stand-in shop seeds 11 starter categories · 51 quick add (name only; pack count > 0; validation = name, count > 0, riel decimals, barcode used) · 52 underline wholesale/cost · 53 one category per item · 54→56→57 one price row open at a time, chevron header toggles it · 55 staging flavor removed · 58 note in the sheet only, no 🔒 on cost · 59 labels `ដប` / `កេះ (12)`, Home shows 3 prices then `+n ទៀត` · 60 every sheet via `showAppSheet` (opens part way, grows as it scrolls).
Also: one bottom-bar style (hug-width pill), `៛ $` segmented switch as one semantics node, theme inputs are 50 px, add-row label `បន្ថែមតម្លៃទំនិញ`, Khmer "item" is always `ទំនិញ`.

## Tried and failed / gotchas
- **Gate commits:** a chained `analyze; test; git commit` once committed red work (`fa17f95`, fixed in `fddfa24`). Commit only if analyze says "3 issues found" and tests have no "failed" (see memory `gate-commits-on-checks`).
- Drift `watch…().first` never settles under a widget test's fake clock: one-time reads use a plain query (`ItemDao.priceSettings`).
- `dart format <folder>` rewraps untouched files: format only files you edited.
- Bulk-replacing a Khmer word hit a shared key (`addItem` was the customer page's button); check every usage of a key first.
- Baseline/semantic alignment: Khmer and Latin glyphs sit at different heights; rows that mix them use `CrossAxisAlignment.baseline`.
- Visual checks: render goldens with the real font (`FontLoader('KantumruyPro')` from `fonts/`, Material icons from the FVM cache) into the scratchpad, then delete the temp test.

## Verified / not verified
- Every commit: analyze at the 3-issue baseline; tests green (core 41, sync 29, l10n 4, ui 81, shop 122, app 99).
- The user checked most screens on their phone during the session.
- Not verified: anything against the real API; the Telegram CI build/send step (first run was cancelled at the APK build, before sending); iOS build after the staging removal.

## CI
- `.github/workflows/dev-telegram.yaml`: analyze, test, build the development arm64 APK, send to Telegram. **Manual only** (Actions › Run workflow) until the redesign ships. Secrets are set. Firebase App Distribution + link was discussed as an alternative if the APK passes 50 MB.

## Open questions
- Unknown-barcode screen (issue 22): not on the canvas; decide before building the scan flow.
- §9 of the plan (starter categories, default rate, editor vs viewer) — with the shop families.
- Khmer time-of-day bands (from the last handoff) still unconfirmed.

## Pointers
- Issues: `.scratch/redesign/issues/NN-*.md` (status lines + comments)
- Key code: `packages/jabhouy_shop/lib/src/` (`data/item_repository.dart`, `data/db/item_dao.dart`, `models/item.dart`, `models/item_draft.dart`, `ui/views/item_form_page.dart`, `ui/views/price_settings_page.dart`, `ui/widgets/{items_tab,item_details_sheet,price_row_editor,category_picker_sheet}.dart`, `ui/bloc/{item_form,item_list,price_settings}/`), `packages/jabhouy_ui/lib/src/widget/{app_sheet,money_input,chips,app_bottom_nav}.dart`, `lib/settings/ui/settings_page.dart`, `lib/home/views/home_page.dart`, `lib/app/routes/app_routes.dart`
- API contract: https://github.com/sokhengpory/jabhouy-api/issues/2 (nicknames, barcode, empty prices, packQty ≥ 1 posted 2026-10-19)

## Suggested skills
`ponytail` for each change, `tdd` for logic, `verification-before-completion` before claiming done.

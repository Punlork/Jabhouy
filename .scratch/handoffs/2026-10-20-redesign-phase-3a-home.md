# Handoff: build issue 23 (Home find-first), then 18 / 11 / Phase 4

## Goal
Keep building the shop-app redesign issue by issue, offline-first: plan → user approves → test-first build → render check → gated commit → push to `dev`. Plan and decisions 1–60 (they override the body): `.scratch/redesign/plan.md`. Design canvas: https://claude.ai/artifact/7yB2Q6kx5udyawUJUPNZc2 (read with the Artifact tool, `project/<Screen>.dc.html`; index `project/canvas.json`).

## State
- **Done this session** (each issue file has a `## Comments` note): 16 (categories & units screen), 20 (ranked search), 21 (recently viewed, data only), 22 (barcode scan; device check pending). Also: Settings Help/diagnostics row removed, item-form errors restyled (one `ErrorLine` style, under the field's own line), `AppSheet` footer pinned to the bottom.
- **In progress:** issue 23 (`.scratch/redesign/issues/23-*.md`). Plan written and posted, **not yet approved**, no code started. The plan (below) needs the user's OK first.
- **Not started, in order:** 23 → 18 sign-in redesign → 11 sync `/changes` (blocked on the API owner's work). 24 photo dropped for now. Then Phase 4 (Credit).

## Issue 23 plan as posted (awaiting approval)
1. Restyle the shared `ShopHeader` (`packages/jabhouy_shop/lib/src/ui/widgets/shop_header.dart`) to canvas ១: muted 54 px search, clear `✕` while typing, dark 54×54 scan button (flag), gear. Credit tab shares it and keeps its filter button. No mic (voice flag not built).
2. RecentPills under the chips (`ItemRepository.watchRecentItems`, issue 21): clock icon, name (ellipsized), first price bold; tap → `showItemDetails`; hidden when empty and while searching.
3. While searching: header `លទ្ធផល n`; rows matched by nickname show `ឈ្មោះផ្សេង៖` with the match highlighted; dashed card `រកមិនឃើញទំនិញដែលចង់បាន?` + `បន្ថែម «query»` opening Add item with the name filled (not for viewers).
4. `ItemListCubit` watches items once and runs `searchItems` in memory (no DB re-query per keystroke); gives `SearchHit.matchedNickname`.
5. Pills + list header slide with Home's chrome (`_chromeVisible` in `lib/home/views/home_page.dart`); chips stay pinned (decision 43).
Canvas files: `HomeFindPills`, `HomeSearch`, `HomeFindScrolled`.

## Decisions made (and why)
- Khmer: a category's unit is **ពាក្យកាត់** everywhere; screen title `ប្រភេទទំនិញ និងពាក្យកាត់` (user's call; memory note saved). Settings count stays `{n} ប្រភេទ`.
- Categories page copies Prices & currency's style (user: "should follow current style"). `saveCategory`/`reorderCategories` refuse a viewer at the repository.
- Search is our own ~60 lines, no package (user asked "third-party?"). Khmer typing-order normalization deferred until testers show mismatches (note in issue 20).
- Unknown barcode: `រកមិនឃើញ · code` + `បន្ថែមទំនិញ` (Add item with the code on row 1) + `ស្កេនបន្ទាប់`. Claude picked it when the user answered "continue" without choosing; easy to change.
- The scanner is passed in as a function (`scanBarcode` / `onScanPressed`, null = flag off), so `jabhouy_shop` never reads `getIt`, and tests fake it.
- Issue 23: keep decision 43 (chips pinned) over the canvas's scrolled frame, which pins search instead; keep today's search hint until voice exists (canvas hint says "or speak").

## Tried and failed
- A Python edit matched a `],` too early and broke `settings_page.dart` (fixed same session). Anchor multi-line edits on unique text.
- `dart format` on whole test files rewraps untouched tests (3 times this session). Format only new files; for edited files, re-insert your block into the `HEAD` version.
- A `Border` with only some sides plus `borderRadius` asserts in Flutter; the scanner frame is a `CustomPainter`.
- `ReorderableListView.onReorder` is deprecated in this Flutter; use `onReorderItem` (index already adjusted).

## Verified / not verified
- Verified on every commit: `fvm dart run melos run analyze` = 3 issues (baseline), `fvm dart run melos run test` all 6 suites green (shop 151). Screens rendered with the real font via a temporary golden test (scratchpad, deleted after).
- Not verified: the camera scanner on a device, and issue 22's "under 2 s offline on Android" (the user's check); drag-reorder by finger; iOS build after adding `NSCameraUsageDescription` (Info.plist also lacks a photo-library text, which `image_picker` needs; not fixed).

## Git
Branch `dev`, pushed, last commit `f689e2a feat(shop): barcode scan …`. Uncommitted: only the user's own trailing-newline edit to `.scratch/redesign/issues/20-ranked-search.md`; leave it out of commits.

## Open questions
- Issue 23 plan approval (above).
- `plan.md` §9 (starter categories, default rate, editor vs viewer) is the shop families' call.

## Next step
Ask the user to approve the issue 23 plan above (or adjust it), then build it test-first, starting with the `ItemListCubit` in-memory search + recents state (`item_list_cubit.dart`, `item_list_state.dart`; `@CopyWith` → `fvm dart run melos run gen`).

## Pointers
- Issues: `.scratch/redesign/issues/23-*.md`, `18-*`, `11-*`; tracker rules `docs/agents/issue-tracker.md`
- Rules: `CLAUDE.md`, `ARCHITECTURE.md`
- Code: `packages/jabhouy_shop/lib/src/{logic/item_search.dart,ui/bloc/item_list/,ui/widgets/items_tab.dart,ui/widgets/shop_header.dart,ui/views/barcode_scanner_page.dart}`, `lib/home/views/home_page.dart`, `lib/app/routes/app_routes.dart` (formItem reads `existingItem`, `barcode`)
- Previous handoff: `.scratch/handoffs/2026-10-19-redesign-phase-3-shop.md`

## Suggested skills
- `ponytail`: smallest complete change per issue.
- `tdd`: cubit and widget behaviour test-first.
- `verification-before-completion`: before claiming done or committing.
- `domain-modeling`: if a new term appears (update `GLOSSARY.md`).

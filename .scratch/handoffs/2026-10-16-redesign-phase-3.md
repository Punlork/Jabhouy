# Handoff: shop redesign, Phase 3 in progress

## Goal
Implement the shop-app redesign (Shop price list + Credit) offline-first, with a friend (Sokheng) building the backend from an agreed contract. The plan and every decision live in `.scratch/redesign/plan.md`; the 40 numbered decisions at its bottom override its body.

## State
- **Done:** plan review (40 decisions), ADR 0001, glossary terms, API contract + 8 backend tasks on GitHub, Phase 1 (issues 01–08: tokens, font, money, l10n, components, Khmer date text), Phase 3 issues 09 (schema 9), 10 (CurrentShop + fake `/me`), 12 (ItemRepository).
- **Not started (Phase 3):** 11 sync rewrite, 13 Home, 14 item sheet, 15 item form (incl. PriceRowEditor), 16 categories & units, 17 shop settings & profile, 18 sign-in redesign. Then Phase 4 (Credit), 5 (voice), 6 (release + schema 10 drop), 7 (family sharing).
- Backend (Sokheng): not started as far as known; contract is issue #2.

## Decisions made
All recorded in `.scratch/redesign/plan.md` (decisions 1–40) and `docs/adr/0001-offline-first-shared-shops.md`. Most load-bearing for the next work:
- New tables sit beside old ones (schema 9); schema 10 drops old ones at release (26).
- One `ItemRepository`/`ItemDao`; category model is `ItemCategory`; packages read the shop via `ShopScope` (core); fake shop `syncs == false` so nothing is queued (40).
- `FEATURE_SERVER_SHOPS` flips fake → real `/me` (one line per flavor config).
- PriceRowEditor is built in `jabhouy_shop` during issue 15, not in `jabhouy_ui` (39).
- Keep the name `PriceOption` (matches glossary and API `prices`).
- Viewer role label `មិនអាចកែតម្លៃ` (38); viewers can record credits (14).

## Tried and failed
- Running `dart format` on whole folders rewraps untouched files (new tall style). Format only files you created; for edited existing files, don't format.
- `intl` `DateFormat` in plain tests throws (locale data not initialized); English date text is formatted by hand in `jabhouy_l10n/lib/src/date_text.dart`.
- The plan's light `placeholder` #767676 failed contrast on muted fields; now #686866.
- Email can't be optional: Better Auth `user.email` is NOT NULL.

## Verified / not verified
- Verified each commit: `fvm dart run melos run analyze` = 3 issues (baseline), `fvm dart run melos run test` all green (core 40, sync 29, l10n 4, ui 76, shop 56, app 96).
- Light and dark theme seen on the emulator. Kantumruy font rendering on device: user asked to check; no result reported.
- Not verified: anything against the real API (not built yet).

## Git
- Branch `dev`. Everything committed in this session; push status: see final message of the session.
- Last feature commit: `f48554b feat(shop): ItemRepository ...`.

## Open questions
- Khmer time-of-day hour bands (ព្រឹក 05–11, រសៀល 12–16, ល្ងាច 17–18, យប់ 19–04) await the user's confirmation.
- §9 of the plan: starter categories, default rate, who is editor/viewer — the user settles with the shop families.
- `FEATURE_GOOGLE_SIGN_IN` must be on in production before release (only way to join, decision 37).

## Next step
Plan issue 15 (add/edit item form with PriceRowEditor) in `.scratch/redesign/issues/15-item-form.md`, post the plan to the user, wait for approval, then build test-first. Then 13 (Home).

## Pointers
- Plan + decisions: `.scratch/redesign/plan.md`
- Local issues (status lines): `.scratch/redesign/issues/01..18-*.md`
- ADR: `docs/adr/0001-offline-first-shared-shops.md`; glossary: `GLOSSARY.md`
- API contract: https://github.com/sokhengpory/jabhouy-api/issues/2 (tasks #3–#10, board https://github.com/users/sokhengpory/projects/1); drafts in `.scratch/redesign-api/`
- Key code: `packages/jabhouy_ui/lib/src/theme/app_tokens.dart`, `packages/jabhouy_ui/lib/src/widget/`, `packages/jabhouy_core/lib/src/money/money.dart`, `packages/jabhouy_core/lib/src/database/app_database.dart`, `lib/membership/`, `packages/jabhouy_shop/lib/src/data/item_repository.dart`

## Suggested skills
- `ponytail` for each build step (smallest complete change).
- `tdd` for repository and form logic.
- `domain-modeling` when a new term appears (update `GLOSSARY.md`).
- `verification-before-completion` before claiming an issue done.

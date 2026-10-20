# P4 Step 7: Cut over and remove the old Credit code

Status: done
Blocked by: 26, 28, 30

- Home uses the new Credit tab only. Delete `lib/loaner/`, `lib/customer/` (page, auto-complete field, blocs), their routes (`formLoaner`, `customer`), DI entries, sync adapters, tests, and the Settings customer entry. Update ARCHITECTURE.md and GLOSSARY.md (Credit, Credit item, Customer).

**Done when:** analyze = baseline, all tests green, grep finds no `Loaner` outside the old-table drop notes.

## Comments

- Deleted `lib/loaner/`, `lib/customer/`, their tests, DI entries, sync adapters, the `form_loaner` and `customer` routes and names, the Settings customers row, and Home's loaner search and filter sheet. `HomeTab.loaner` is now `HomeTab.credit`. The new Credit tab was already live (issue 26).
- Kept on purpose until the release-time old-table drop (decision 26): the old `Customers` and `Loaners` tables and the `customer` / `loaner` `SyncEntityType` values in `jabhouy_core` (the session cleanup and sync-indicator tests still use them), the engine's old pull order, and the unused ARB strings and icon assets.
- Updated CLAUDE.md and ARCHITECTURE.md (Credit example, `/changes` section). GLOSSARY.md already used Credit, Customer, Credit item.

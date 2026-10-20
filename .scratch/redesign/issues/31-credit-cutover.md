# P4 Step 7: Cut over and remove the old Credit code

Status: open
Blocked by: 26, 28, 30

- Home uses the new Credit tab only. Delete `lib/loaner/`, `lib/customer/` (page, auto-complete field, blocs), their routes (`formLoaner`, `customer`), DI entries, sync adapters, tests, and the Settings customer entry. Update ARCHITECTURE.md and GLOSSARY.md (Credit, Credit item, Customer).

**Done when:** analyze = baseline, all tests green, grep finds no `Loaner` outside the old-table drop notes.

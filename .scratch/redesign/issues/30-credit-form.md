# P4 Step 6: Add / edit Credit (canvas ៩, ៩ខ, ១០)

Status: done
Blocked by: 27, 28, 29

- Customer button opens the picker (no typed name). Lines list with QtyStepper and totals; `បន្ថែមទំនិញពីបញ្ជីតម្លៃ` opens the item picker. Amount: read-only `គណនាពីទំនិញ` with lines, typed MoneyInput without; ៛/$ switch re-converts with the snapshot; converted value under it. DateTimeField `ថ្ងៃ និងម៉ោងជំពាក់` (now on add), optional `ត្រូវសង`, status SegmentedControl, note, sticky `រក្សាទុក`.

**Done when:** 2 × ដប + 5 × គីឡូ saves 25,000 ៛; editing keeps the original rate snapshot; a Credit with no lines saves a typed amount or none.

## Comments

- Route `form_credit` (`extra: {existingCredit}`), `CreditFormCubit` + `CreditFormPage`. The pickers reach the page as functions (`pickCustomer`, `pickItems`) from the route, so the page never reads `getIt` and tests fake them. Home's add button and the details sheet's `កែ` now open it; the add button is no longer disabled.
- With lines the amount is read-only (decision 9) with a ៛/$ chip that re-converts the lines at the Credit's rate; without, the shared `MoneyInput`. A new Credit takes the shop's currency and rate; an edit keeps its own rate.
- Times: stored UTC, picked and shown in UTC+7. Due date is the local day (`toIsoDate`), clearable.
- No mic (voice flag not built).

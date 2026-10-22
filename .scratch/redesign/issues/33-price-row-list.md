# P3c Step 2: Price rows as a list in the item form

Status: done (device check pending)
Blocked by: 32

- Replace the inline-expanding Price option editor in the item form with a white card of compact rows (canvas `៣`, `៤ក`): unit badge (64 px, `ដប`, with `×24` under it when the quantity is above 1), the price on the right (18 px bold), a small line under it with `ដុំ …` and `ដើម …` only when set, a barcode icon when the row has one, and a `›`.
- A row with no price shows `មិនទាន់មានតម្លៃ` in the warning colour, not `0`.
- A price in the other currency shows `≈` under it (as the Home and details sheet do).
- Section header `តម្លៃ` with the hint `ចុចលើតម្លៃដើម្បីកែ` on the right (hidden when there are no rows). Tapping a row opens the sheet from ticket 32 in edit mode.
- Under the card: dashed `+ បន្ថែមតម្លៃ (ឧ. កេះ ×24, បេ)` button, opens the sheet in new mode.
- Empty state (canvas `៤`): card `មិនទាន់មានតម្លៃ` + `អាចរក្សាទុកសិនបាន ហើយបន្ថែមតម្លៃពេលក្រោយ`, then the dashed button.
- Save-time problems (decision: errors under the field's line) now open the sheet of the first bad row, as `_openRowId` does today, and show the message there. A row with a problem has a red outline in the list.
- Remove `PriceRowSummary` expand mode and `_openRowId` once nothing uses them.

**Done when:** `ដប + កេះ ×24` is entered in one form and shows as two rows; tapping a row edits it in the sheet; saving with a bad row opens that row's sheet; no row shows `0 ៛`; existing item-form tests are updated, not deleted.

## Comments

- The item form now shows a white card of `PriceRowSummary` rows (unit badge with `×n`, price with `≈`, `ដុំ` / `ដើម` line, barcode mark, `›`) and the dashed `+ បន្ថែមតម្លៃ` button; both open `showPriceSheet`. `_openRowId` and the inline editor are gone; `PriceRowHeader` now labels the sheet's fields.
- A new item starts with no rows and shows `មិនទាន់មានតម្លៃ` + `អាចរក្សាទុកសិនបាន…` (new strings `priceTapToEdit`, `priceNoneYet`). Decided: zero prices is allowed; GLOSSARY.md now says zero or more.
- A scan still starts the item with one row carrying the barcode.
- The sheet validates its own row, so a bad number cannot reach the form. The only save-time row problem left is a barcode another Item uses: the form reopens that row's sheet with the message.
- Tests: `item_form_page_test.dart` rewritten around the sheet (add, edit, delete, chips, scan, barcode-in-use); the old open/close-header test became add/edit/remove.
- Not verified: the look on a device.

# P3c Step 2: Price rows as a list in the item form

Status: open
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

# P3c Step 1: Price sheet (add and edit one Price option)

Status: done (not wired into the form until 33)
Blocked by: 15

- New bottom sheet (`AppSheet`) for one Price option, from canvas `៤ក` (new, title `តម្លៃថ្មី`, button `បន្ថែម`) and `៣ក` (edit, title `កែតម្លៃ`, button `រួចរាល់`). Header: the unit badge (dark) + title + `✕`.
- Fields, top to bottom: `លក់ជា` (unit, text) and `ចំនួន ×` (pack quantity, 70 px); unit chips with the hint `ឯកតាសម្រាប់ «{category}»` (keep today's 5 chips + `ទាំងអស់ ›` unit sheet); `តម្លៃលក់` (20 px bold) with the ៛ / $ switch inside the field and a `≈ …` line under it; one row with `ដុំ` and `ដើម` (lock icon) fields and a 44 px barcode scan button (flag).
- Edit mode only: `🗑 លុបតម្លៃនេះ` (red text). Offered on every row: an Item may have zero prices (decided; validation already allowed it).
- Reuse the field logic of `PriceRowEditor` (validation, ៛ ↔ $ conversion of wholesale and cost, money rules from `jabhouy_core`). Move it into the sheet; do not copy it.
- A new row is added to the form only when the sheet's `បន្ថែម` is tapped; closing the sheet adds nothing.
- Canvas aria-label for `ដើម` says `(មើលឃើញតែម្ចាស់ហាង)`. That contradicts decision 2 (cost is visible to every Member). Keep decision 2; correct the canvas label.

**Done when:** a row is added and edited only through the sheet; ៛ ↔ $ converts wholesale and cost as today; `បន្ថែម` with an empty price shows the usual error under the field; closing the sheet changes nothing; widget tests cover add, edit, delete and close.

## Comments

- `showPriceSheet` in `packages/jabhouy_shop/lib/src/ui/widgets/price_sheet.dart` returns `PriceSaved(draft)`, `PriceDeleted`, or null (closed, or a new row left empty). It wraps the existing `PriceRowEditor`, so validation and ៛ ↔ $ conversion are unchanged; `បន្ថែម` / `រួចរាល់` runs `ItemDraft.validate` on that one row and keeps the sheet open with the message.
- New strings `priceNew` (`តម្លៃថ្មី`) and `priceDone` (`រួចរាល់`).
- Barcode-in-use is only known to the cubit at save time, so it is not checked in the sheet; 33 reopens the sheet of that row with the message.
- The canvas says `ឯកតា`; the app keeps `ពាក្យកាត់` (user's call, issue 16).
- Layout follows canvas ៤ក: labels over `លក់ជា` / `ចំនួន`, unit chips under that row, `តម្លៃលក់` on its own full-width row, then `ដុំ` / `ដើម` as muted boxes beside the scan button. This lives in `PriceRowEditor` (only the sheet uses it now); `PriceRowHeader` is gone.
- Not verified on a device.

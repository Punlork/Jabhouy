# P3c Step 1: Price sheet (add and edit one Price option)

Status: open
Blocked by: 15

- New bottom sheet (`AppSheet`) for one Price option, from canvas `៤ក` (new, title `តម្លៃថ្មី`, button `បន្ថែម`) and `៣ក` (edit, title `កែតម្លៃ`, button `រួចរាល់`). Header: the unit badge (dark) + title + `✕`.
- Fields, top to bottom: `លក់ជា` (unit, text) and `ចំនួន ×` (pack quantity, 70 px); unit chips with the hint `ឯកតាសម្រាប់ «{category}»` (keep today's 5 chips + `ទាំងអស់ ›` unit sheet); `តម្លៃលក់` (20 px bold) with the ៛ / $ switch inside the field and a `≈ …` line under it; one row with `ដុំ` and `ដើម` (lock icon) fields and a 44 px barcode scan button (flag).
- Edit mode only: `🗑 លុបតម្លៃនេះ` (red text). Not offered while it is the Item's last row? Decide in the ticket; the canvas does not say.
- Reuse the field logic of `PriceRowEditor` (validation, ៛ ↔ $ conversion of wholesale and cost, money rules from `jabhouy_core`). Move it into the sheet; do not copy it.
- A new row is added to the form only when the sheet's `បន្ថែម` is tapped; closing the sheet adds nothing.
- Canvas aria-label for `ដើម` says `(មើលឃើញតែម្ចាស់ហាង)`. That contradicts decision 2 (cost is visible to every Member). Keep decision 2; correct the canvas label.

**Done when:** a row is added and edited only through the sheet; ៛ ↔ $ converts wholesale and cost as today; `បន្ថែម` with an empty price shows the usual error under the field; closing the sheet changes nothing; widget tests cover add, edit, delete and close.

# P3 Step 3: Add and edit item form

Status: open
Blocked by: 12, 19

- Photo + name; nicknames as removable chips with `+ ឈ្មោះផ្សេង` (optional). Category QuickPickChips + `ទាំងអស់ ›`, suggested from the name by keyword, last used otherwise.
- PriceRowEditor in `jabhouy_shop` (decision 39): unit, optional `×` count, selling MoneyInput, remove. Below it one quiet line (canvas ៣ក): `ដុំ` and `ដើម` fields, no border, `surfaceSubtle` fill, 40 px, 14 px text, each only if enabled in shop settings; no owner-only lock (decision 2). Unit chips under the first row; `+ បន្ថែមតម្លៃ`. The row's barcode button comes in issue 22.
- Note (optional); sticky `រក្សាទុក`, never disabled.
- Validation on save (not while typing), red with an icon under the field, scroll to the first problem (canvas ៤ខ):
  - name empty → `សូមបញ្ចូលឈ្មោះទំនិញ`
  - letters, decimals in ៛ (`តម្លៃរៀលមិនអាចមានទសភាគ`), more than 2 decimals in $
  - pack count 0 or 1 → `ចំនួនក្នុងកញ្ចប់ត្រូវលើសពី ១`
  - barcode used by another Item in the Shop → `បាកូដនេះប្រើរួចហើយសម្រាប់ «X» · មើល` (decision 41)
  - at least one row with a unit or price; an empty price saves as null.
- Duplicate name is a warning only (canvas ៤គ, decision 49): `មានទំនិញឈ្មោះនេះរួចហើយ · មើល · ឬរក្សាទុកជាទំនិញថ្មី`.

**Done when:** creating ដប 3,000 ៛ + កេះ ×24 60,000 ៛ in one form saves one Item with two Price options; a row left empty saves null; each error above blocks saving with its message; a duplicate name still saves.

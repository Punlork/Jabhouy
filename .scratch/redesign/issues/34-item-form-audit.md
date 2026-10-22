# P3c Step 3: Item form and sheet copy against the new canvas

Status: done (audit only, no code change; photo tile moves to 24)
Blocked by: 33

Check these against canvas `៤`, `៤ក`, `៣`, `២`, `៥` and build only the gaps. Several may already match; note which in a comment.

- Name row: photo tile (88 px, initial letter when it has a photo name) + name field with mic; nicknames under it: chips `ទឹកធំ ✕`, `+ ឈ្មោះផ្សេង (ឧ. ទឹកធំ, Kulen)`.
- Category: `ប្រភេទ` chips with a check on the chosen one, `ទាំងអស់ ›` opens the category sheet. Hint under the chips: `ជ្រើសប្រភេទ ងាយស្រួលស្វែងរកពេលក្រោយ` (none chosen) or `បានណែនាំតាមឈ្មោះ · ចុចដើម្បីប្តូរ` (suggested from the name).
- Note field with mic, placeholder `អ្នកផ្គត់ផ្គង់, កន្លែងដាក់ទំនិញ…`.
- Footer: full-width `រក្សាទុក`, never disabled.
- Item details sheet (`២`): each Price option shows `លក់ដុំ: —` and `ដើម: —` when unset, `≈` under a price in the other currency, and `កែចុងក្រោយ {ថ្ងៃ} ដោយ {ឈ្មោះ}`; buttons `កែតម្លៃ` (dark) and `លុប` (red outline), `លុប` only for owner and editor.
- Boards marked `🗑 លុប` (Rows A–F, Variants underline) are discarded options. Do not build them.

**Done when:** each bullet is either confirmed as already matching (with the file that shows it) or built; analyze at baseline; all tests green.

## Comments

Checked against canvas ២, ៣, ៤, ៤ក, ៥ in `packages/jabhouy_shop/lib/src/ui/`:

- Name field with mic, `ឈ្មោះផ្សេង` chips with `✕` and `+ ឈ្មោះផ្សេង (ឧ. ទឹកធំ, Kulen)`: match (`views/item_form_page.dart`, `_nameSection`).
- Category chips (chosen first, five at most), `ទាំងអស់ ›` opening the category sheet, and the two hints (`categoryHint`, `categorySuggested`): match (`_categorySection`).
- Note with mic and placeholder, full-width `រក្សាទុក` that is never disabled: match.
- Item details sheet: `លក់ដុំ` and `ដើម` lines, `≈` for the other currency, last edited line, `កែតម្លៃ` and red `លុប` for editors only: match (`widgets/item_details_sheet.dart`). Cost is shown to every Member, as decision 2 says; the canvas's `(មើលឃើញតែម្ចាស់ហាង)` label is wrong.
- **Gap:** the 88 px photo tile left of the name field (`បន្ថែមរូបថត`, or the item's initial). The form has no photo at all today. That is issue 24 (offline photo); a tile that does nothing would mislead, so it waits for 24.
- Dashed borders (nickname and price add buttons) are drawn solid or outlined; already a noted `shortcut:` for nicknames.
- Discarded boards (Rows A–F, Variants underline): not built.

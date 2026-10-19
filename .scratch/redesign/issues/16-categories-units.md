# P3 Step 3: Category picker and categories & units

Status: done
Blocked by: 12

- Category picker sheet: search, radio list, `បង្កើតប្រភេទថ្មី`.
- Settings → `ប្រភេទ និងឯកតា`: add, rename, hide, reorder categories and their units. Units are hidden, never deleted.

**Done when:** a hidden unit disappears from the form chips but items using it still show it.

## Comments

- 2026-10-19: done in the item form: top five category chips (chosen first) + `ទាំងអស់ ›` opening the picker sheet (search, checked row, `បង្កើតប្រភេទថ្មី`). Creating a category saves it and picks it.
- Still open: the categories & units screen from Settings (rename, hide, reorder, units). Status stays open until it exists.
- 2026-10-19: Categories & units screen built. Settings › ហាង › `ប្រភេទ និងឯកតា` (`N ប្រភេទ`) lists every category in order, hidden ones dimmed with `លាក់`; drag handle reorders (`reorderCategories` rewrites every `sortOrder`, one sync job each); `+ បង្កើតប្រភេទថ្មី`. Tap → `AppSheet`: name, `លាក់` switch, unit chips (checked = shown; tap to hide/show), `+ ឯកតា`, fixed `រក្សាទុក`. Viewer: read-only, and `saveCategory`/`reorderCategories` refuse a viewer. Settings' Help › diagnostics row removed (7 taps on the title still opens it). Left out: delete (decision 25).

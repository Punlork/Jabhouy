# P3 Step 3: Home list and grid

Status: resolved
Blocked by: 12

- SearchField, list/grid toggle (list default, remembered), settings button.
- FilterChips: `ទាំងអស់`, the warning chip `មិនទាន់មានតម្លៃ (n)` for editors and owners, then categories. No banner.
- List row: 48 px thumbnail or first letter, name, one line per Price option with PriceDisplay. Grid card: same price lines.
- Swap in `AppBottomNav` with `បន្ថែមទំនិញ`.

**Done when:** an item with ដប + កេះ ×24 shows as one row with two prices; no screen shows `0 ៛`; the warning chip filters to items with a missing price.

## Comments

- 2026-10-19: `ItemsTab` + `ItemListCubit` replace `ShopTab` on Home; Home reads only the new tables from now on (old items stay in the old tables, decision 26). `AppBottomNav` replaces the floating bottom bar; `flutter_floating_bottom_bar` removed.
- Tapping a row opens the edit form until issue 14's details sheet exists.
- The header keeps its current search field and gear; the redesigned top row (scan button, mic) is issue 23. The shop tab's filter button is gone: chips filter.
- List/grid is remembered in SharedPreferences (`item_list_grid`), now registered in DI.
- Verified by cubit and widget tests; not yet seen on a device.

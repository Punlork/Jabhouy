# P3a Step 4: Home find-first layout

Status: done (uncommitted; device check pending)
Blocked by: 13, 20, 21, 22

- Top row (canvas ១): SearchField `ស្វែងរក ឬនិយាយឈ្មោះទំនិញ` · ScanButton (flag) · gear. No shop-name row.
- RecentPills under the chips, hidden when empty; list header `ទំនិញ {n} មុខ · ក–អ` with the grid/list toggle. No `≈` on the home list.
- Scroll down: category FilterChips stay pinned; search row, pills and header slide away and return on a small scroll up (decision 43).
- Searching replaces the list with `លទ្ធផល n`, matched nicknames shown, then the card `រកមិនឃើញទំនិញដែលចង់បាន?` / `បន្ថែម «{query}»` opening Add item with the name filled.

**Done when:** the pills row is hidden on a fresh install; searching `ទឹកធំ` shows the nickname match; `បន្ថែម «…»` opens the form with that name; chips stay visible while scrolling.

## Comments

- Built per the handoff plan. `ItemListCubit` now watches items once (category/chip filter) and ranks searches in memory, so `matchedNickname` reaches the UI and typing no longer re-queries Drift. Pills and list header slide with Home's chrome via `ItemsTab.chromeVisible`; chips stay pinned.
- Searching always renders the list layout (grid off while searching) so the not-found card can span the width. Not offered to viewers.
- `ItemFormPage(name:)` prefills the name; route extra key `name`.
- Not verified: look on a device (54 px header, pills), scroll-away of pills.

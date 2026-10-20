# P4 Step 5: Item picker (canvas ៩ក)

Status: done
Blocked by: 25

- Tall sheet: SearchField (ranked search from jabhouy_shop), category chips, every Price option as its own row with `+` turning into a QtyStepper, selected rows highlighted, sticky footer `បានជ្រើស n មុខ` + running total + `បន្ថែមទៅការជំពាក់`. No mic yet.

**Done when:** picking 2 × ដប and 5 × គីឡូ returns two lines with a snapshot of name, unit, price and currency.

## Comments

- `showItemPicker(context, itemRepository, currency:, khrPerUsd:, initial:)` returns the Credit's whole set of lines (null if dismissed). `ItemPickerCubit` reads every Item once and narrows by category and ranked search in memory; a choice survives a search.
- A line already on the Credit keeps its id and snapshot (name, unit, price) when its count changes; lines whose Price option no longer exists pass through untouched. An option with no price shows `មិនទាន់មានតម្លៃ` and cannot be added.
- `AppSheet` gained an optional `pinned` slot (full width, stays under the title) so the search and chips stay put while the list scrolls. No mic yet.

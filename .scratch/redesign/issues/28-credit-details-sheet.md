# P4 Step 4: Credit details sheet (canvas ៨)

Status: done
Blocked by: 26

- Name, StatusPill, date and time; amount box (other currency shown); items and note; primary `សម្គាល់ថាសងរួច` (status + `paid_at`); `កែ`; `លុប` for owner and editor only.

**Done when:** marking paid moves the Credit to `សងរួច` and the summary drops; viewers see no `លុប`; a render check matches the canvas.

## Comments

- `showCreditDetails(context, credit, onEdit:)` loads the Credit with its lines through `CreditListCubit` (`credit`, `markPaid`, `delete`, `canDelete`) and opens the standard AppSheet; the list's row tap calls it. Buttons live in the sheet's footer, not mid-content as drawn, so they stay put while items scroll.
- `កែ` shows only when `onEdit` is given; the form is issue 30, so it is hidden until then.
- Delete asks first (`confirmDelete`); viewers see no `លុប` but can mark paid.

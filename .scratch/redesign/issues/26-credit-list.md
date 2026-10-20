# P4 Step 2: Credit list (canvas ៧)

Status: done (uncommitted; device check pending)
Blocked by: 25

- Credit tab shows the new list: SearchField (customers), dark summary card `នៅជំពាក់សរុប` (unpaid known amounts in the default currency, other currency below, count unpaid, count without amount), FilterChips `មិនទាន់សង` (default) / `សងរួច` / `ទាំងអស់`, rows (name, amount or `មិនទាន់មានចំនួន`, one-line note, StatusPill, date). Tap opens details (issue 28).
- The old filter sheet is dropped (user, 2026-10-20); the shared header shows no filter button on this tab.
- Follow canvas CreditList.dc.html.

**Done when:** the chips narrow the list, search narrows by customer name, the summary matches the rows, and a render check matches the canvas.

## Comments

- New `CreditView` + `CreditListCubit` (`lib/credit/ui`). The cubit reads every Credit once and narrows it in memory by the chip and the customer search; the summary is over all unpaid Credits whatever the chip says. Summary counts people (`នាក់`) as the canvas does, not Credits.
- No flag (user, 2026-10-20): Home shows the new tab directly. The add button is disabled until the form (issue 30), since the old form records loans the new list cannot show. The canvas has the search field only, so the shared header is hidden on this tab; Settings stays reachable from the shop tab.
- The new tab starts empty: there is no add form yet and the stand-in shop has no rows in the new tables.
- Rows take the Credit's own currency with the other below; the date shows in UTC+7.
- Widget tests close the cubit and database inside `runAsync`; a cancel under the fake clock never finishes.

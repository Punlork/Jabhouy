# P4 Step 3: Customer picker (canvas ១១)

Status: done
Blocked by: 25

- Sheet via `showAppSheet`: search, rows with name + balance (`ជំពាក់ 23,000 ៛` / `សងរួច`), `បន្ថែមអតិថិជនថ្មី` (the only place a Customer is created, decision 10; mic deferred), ✎ rename per row, delete for owner and editor.

**Done when:** adding, renaming and searching work; deleting a Customer with Credits is refused with a message; viewers get no delete.

## Comments

- `showCustomerPicker(context, repository, selectedId:)` returns the tapped or newly added `CreditCustomer`; `CustomerPickerCubit` holds the list and search. The form (issue 30) calls it.
- Row text: `ជំពាក់ 23,000 ៛`, `ជំពាក់ · មិនទាន់មានចំនួន`, `សងរួច`, nothing for a Customer with no Credit. ✎ opens a small name dialog (rename; `លុប` only for owner and editor); a refused delete shows `customerHasCredits`.
- Tests close the cubits with a one-second `pump` before `runAsync(db.close)`, or the stream cancels never finish under the fake clock.

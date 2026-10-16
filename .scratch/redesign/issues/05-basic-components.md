# Step 2: Basic components

Status: resolved
Blocked by: 01, 02, 04

In `jabhouy_ui`, from tokens only:
- SearchField, FilterChips (with the amber warning chip and count), QuickPickChips, SegmentedControl, StatusPill, QtyStepper.
- LabeledField by extending `CustomTextFormField` (label above, `(មិនចាំបាច់)` suffix, hint, trailing slot).
- BottomSheet by extending `AppBottomSheet` (handle, title, close, sticky footer).
- DateTimeField (date and time buttons, empty time shows `បន្ថែមម៉ោង`).

**Done when:** a widget test per component renders it in Khmer in both themes and passes `meetsGuideline(iOSTapTargetGuideline)` (44 × 44).

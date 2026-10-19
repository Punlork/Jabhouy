# P3 Step 3: Item details sheet

Status: resolved
Blocked by: 12

- `AppSheet`: thumbnail, name, category tag; per Price option the unit, `×qty`, big price, wholesale and cost (`—` when empty).
- `កែចុងក្រោយ {date} ដោយ {name}` from `updated_at` / `updated_by`.
- `កែតម្លៃ` and `លុប` (confirm first) for owner and editor only.

**Done when:** a widget test shows a viewer no edit buttons and an editor both.

## Comments

- 2026-10-19: `ItemDetailsSheet` opens on a tap in `ItemsTab`; `កែតម្លៃ` opens the form, `លុប` confirms then deletes. Wholesale/cost rows follow shop settings.
- "by {name}" needs the editor's Member row; the stand-in Shop has none, so it shows the date alone (`lastEditedOn`).

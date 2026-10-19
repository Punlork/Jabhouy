# P3 Step 3: Shop settings and profile

Status: resolved
Blocked by: 12

- `តម្លៃដែលហាងប្រើ`: selling (always on), wholesale, cost. Currency: default ៛/$, rate `$1 = [4,000] ៛` with last edited, show-converted tick. Owner only; changing the rate asks for confirmation (`settingsRateConfirm`).
- Links: categories & units, Profile (name, Username, `ចេញពីគណនី`), app diagnostics behind `FEATURE_DIAGNOSTICS`.

**Done when:** changing the rate updates every `≈` value and no stored price.

## Comments

- 2026-10-19: Prices & currency screen (canvas ១២ក) and Settings restyled to canvas ១២. Owner-only saves (others read-only, with a note); a new rate asks for confirmation and records when; Home and the details sheet follow settings live; the sheet's ≈ line obeys "show both currencies".
- Settings rows: profile card → existing Profile page; Prices & currency; Customers; Language; Appearance; device role (income only); Diagnostics (flag + 7 taps); sign out; version.
- Left out: Categories & units (issue 16's screen will take that row; the old category page edits the old table), Members (Phase 7). The Profile page itself is not restyled yet.

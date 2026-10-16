# Step 1: Money and date formatting in jabhouy_core

Status: resolved
Blocked by: none

- `Currency` (KHR, USD), `Money` (whole number in riel or cents + currency).
- Conversion with `khrPerUsd`: USD → KHR rounds half up to 100 ៛; KHR → USD to 1 cent.
- Formatting: `30,000 ៛`, `$7.50`, converted prefixed `≈ `.
- Date and time display in Asia/Phnom_Penh: `16 តុលា 2026`, `11:05 ព្រឹក` (ព្រឹក / រសៀល / ល្ងាច / យប់).
- Pure Dart, tested with `dart test`. Same rules as the API (jabhouy-api #10).

**Done when:** tests pass for $7.50 → ≈ 30,000 ៛, 3,800 ៛ → ≈ $0.95, $1.23 → 4,900 ៛, and a UTC `takenAt` of `2026-10-16T04:05Z` shows `11:05 ព្រឹក`.

## Comments

Resolved with money and `toPhnomPenh()` in core. The Khmer date and time text (`16 តុលា 2026`, `11:05 ព្រឹក`) moved to 08, in `jabhouy_l10n`, because month names and times of day are language text.

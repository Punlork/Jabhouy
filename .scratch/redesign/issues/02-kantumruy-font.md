# Step 1: Bundle Kantumruy Pro

Status: open
Blocked by: none

- Add Regular, Medium, SemiBold, Bold (400–700) from `fonts/Kantumruy_Pro.zip` as assets, like NotoSansKhmer in `pubspec.yaml`. No `google_fonts`.
- Kantumruy Pro is the theme font, NotoSansKhmer the fallback; line height 1.5 everywhere.
- Text styles from §1 (page title 20/600 … big amounts 26–28/700); inputs at least 16.
- Remove the zip from the repo after extracting.

**Done when:** Khmer with stacked vowels and subscripts (e.g. `ស្ត្រី`, `ក្សត្រ`) renders unclipped in a widget test golden or on device.

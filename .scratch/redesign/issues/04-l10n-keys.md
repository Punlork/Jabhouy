# Step 1: Localization keys

Status: open
Blocked by: none

- Add the §4 keys (as edited in the plan) to `app_km.arb` and `app_en.arb` in `jabhouy_l10n`; regenerate with `fvm flutter gen-l10n`.
- Remove keys only used by screens the redesign deletes, when those screens go (not now).

**Done when:** `melos run analyze` passes and every new key exists in both languages.

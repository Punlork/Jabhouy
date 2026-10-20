# P3a Step 3: Barcode scan (known codes)

Status: done (device check pending)
Blocked by: 19, 14

- Add `FEATURE_BARCODE_SCAN` (decision 44): `Feature` value, `BuildTimeFeatureFlags` case, key in every `config/features/<flavor>.json`; on in development only.
- Add `mobile_scanner` (decision 47) and the Android camera permission.
- Full-screen scanner with a frame (canvas ១ឃ). Match → sheet `រកឃើញ`, the Item, the scanned row in a dark band with a big price, other rows smaller, `មើលលម្អិត` / `ស្កេនបន្ទាប់`. Several matches (offline duplicate, decision 41) → list them to pick.
- PriceRowEditor barcode button, 44×44 (outlined = none, dark = attached), opens the scanner and fills the row.
- Flag off hides the scan button and the row barcode button.
- Not here: the unknown-barcode sheet (open decision in the plan).

**Done when:** scanning a bottle linked to the `ដប` row opens its price offline in under 2 seconds on a real Android phone; with the flag off, no scan UI shows.

## Comments

- 2026-10-20: Built. `FEATURE_BARCODE_SCAN` (dev on, prod off), `mobile_scanner` 7.4.2, iOS `NSCameraUsageDescription`. Home: scan button beside search → scanner (canvas ១ឃ) → result sheet over the camera: one match (dark band, `មើលលម្អិត` / `ស្កេនបន្ទាប់`), several (pick list), none (`រកមិនឃើញ · code`, `បន្ថែមទំនិញ` opens Add item with the code on its first row — chosen by Claude as the stand-in for §3.1b). Price row: 44×44 barcode button on the ដើម line, dark once attached, red when used elsewhere. Lookup `ItemRepository.itemsWithBarcode` (offline). New route extra key `barcode` for formItem.
- Not verified: the camera itself (no widget test can drive it); the "under 2 s on a real Android phone" check is the user's.

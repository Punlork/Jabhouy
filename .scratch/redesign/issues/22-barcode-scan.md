# P3a Step 3: Barcode scan (known codes)

Status: open
Blocked by: 19, 14

- Add `FEATURE_BARCODE_SCAN` (decision 44): `Feature` value, `BuildTimeFeatureFlags` case, key in every `config/features/<flavor>.json`; on in development only.
- Add `mobile_scanner` (decision 47) and the Android camera permission.
- Full-screen scanner with a frame (canvas ១ឃ). Match → sheet `រកឃើញ`, the Item, the scanned row in a dark band with a big price, other rows smaller, `មើលលម្អិត` / `ស្កេនបន្ទាប់`. Several matches (offline duplicate, decision 41) → list them to pick.
- PriceRowEditor barcode button, 44×44 (outlined = none, dark = attached), opens the scanner and fills the row.
- Flag off hides the scan button and the row barcode button.
- Not here: the unknown-barcode sheet (open decision in the plan).

**Done when:** scanning a bottle linked to the `ដប` row opens its price offline in under 2 seconds on a real Android phone; with the flag off, no scan UI shows.

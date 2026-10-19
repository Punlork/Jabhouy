# Draft: contract addition for find-first (for jabhouy-api #2)

Posted to jabhouy-api #2 on 2026-10-19 (body edited and a comment added); #2 is the source of truth now.

## Shapes: Item

Two new fields; everything else unchanged.

```json
{ "id": "…", "name": "ទឹកអូគូលេនធំ", "nicknames": ["ទឹកធំ", "Kulen"], "categoryId": "…",
  "photoUrl": null, "note": null,
  "prices": [{ "id": "…", "unit": "ដប", "packQty": null, "barcode": "8851234567890",
               "currency": "KHR", "price": 3000, "wholesale": null, "cost": 2500, "sortOrder": 0 }] }
```

- `nicknames`: array of strings, default `[]`, stored as JSON text on `item`. Order kept as sent.
- `barcode`: nullable string on `item_price`. **No unique constraint on the server**: the app checks uniqueness within the shop before saving, and a rare offline duplicate is resolved by the user when scanning. Rejecting the save would drop the whole Item's price edits, because `prices` are replaced as a set.
- Both are written by `PUT /shops/:id/items/:itemId` (owner, editor) and returned by `/changes` like the other Item fields.

No new endpoints. Search and Recently viewed run on the phone.

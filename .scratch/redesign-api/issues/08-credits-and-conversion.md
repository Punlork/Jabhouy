# Credits with items, and the shared conversion function

Status: open
Blocked by: 07

- Conversion function as in the spec, with the three test cases.
- `PUT /shops/:shopId/credits/:id`: any Member. Validate `customer.id` is a live Customer of the Shop; each `total` matches the per-item rule; with items, `amount` equals their sum. 400 `invalid` on a mismatch. Replace the `items` list.
- `DELETE`: owner and editor.

**Done when:** tests pass for 2 × 3,000 ៛ + 5 × 3,800 ៛ = 25,000 ៛; a USD line at snapshot 4,000 converts per item; a wrong `amount` gives 400.

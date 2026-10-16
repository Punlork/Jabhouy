# Items with prices

Status: open
Blocked by: 04

- `PUT /shops/:shopId/items/:id`: upsert the Item and replace its `prices` list. At least one option; prices nullable, never defaulted to 0.
- Any `unit` not among the Category's units is added to them.
- `DELETE`: tombstone the Item and its options. Owner and editor only.

**Done when:** sending the same PUT twice gives one Item; a PUT with one fewer option removes it; a new unit appears in the Category's units.

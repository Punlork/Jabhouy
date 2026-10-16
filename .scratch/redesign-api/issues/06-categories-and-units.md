# Categories with merged units

Status: open
Blocked by: 04

- `PUT /shops/:shopId/categories/:id`: upsert the Category; units merge by `(categoryId, unit)`: add what is named, update `hidden` on what is named, never remove.
- `DELETE`: tombstone. Owner and editor only.

**Done when:** two PUTs naming different units both keep their units.

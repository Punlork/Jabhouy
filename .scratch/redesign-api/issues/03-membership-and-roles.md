# Membership and role checks for /shops/:shopId

Status: open
Blocked by: 02

- Middleware on `/shops/:shopId/*`: 403 `not_member` when the caller is not a Member; puts the role on the context.
- A helper each route calls to require a role; 403 `forbidden_role` otherwise. Role table in the spec.
- Errors use `{ code, message }`.

**Done when:** tests show a non-member gets `not_member` on every route, and a viewer gets `forbidden_role` on item, category and settings writes and on customer and credit deletes, but not on customer or credit upserts.

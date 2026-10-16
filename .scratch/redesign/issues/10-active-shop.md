# P3 Step 1: Active Shop from /me

Status: open
Blocked by: 09

- After sign-in, read `GET /me`; remember the Active Shop id and the user's role on the phone.
- Every local query and write is scoped to the Active Shop.
- Until jabhouy-api #4 is live, a fake `/me` returns one shop with the owner role.

**Done when:** a test signs in against the fake, reads the shop and role, and an item written afterwards carries that `shop_id`.

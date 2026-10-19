# P3 Step 3: Item photo, offline

Status: open
Blocked by: 15

- Split from issue 15: the old form uploads before saving and needs internet; the redesign is offline-first.
- Pick a photo in the item form; keep it on the phone, queue the upload, set `photoUrl` once the server has it.
- Agree the upload endpoint with Sokheng and add it to the API contract (#2 has `photoUrl` but no upload route).

**Done when:** a photo added offline shows on the phone at once and reaches the server after reconnecting; the item saves even if the upload fails.

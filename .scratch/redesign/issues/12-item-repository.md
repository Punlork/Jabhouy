# P3 Step 2: Item and category repositories

Status: open
Blocked by: 09, 10

- Repositories return `Result<T>`; writes go to Drift, then `SyncEngine.enqueue`, then drain if online.
- Item save writes the Item and its full Price option list together (decision 27); prices null, never 0.
- Unit order for chips counted from Price options on the phone (decision 13).

**Done when:** repository tests cover save, edit (option removed), delete (tombstone), and unit counts.

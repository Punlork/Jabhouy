# P3a Step 2: Recently viewed

Status: open
Blocked by: 19

- Opening the item sheet records the Item in `recent_item` for the Current Shop; keep the newest 10, de-duplicated (decision 46).
- A stream of recent Items with their first price for RecentPills.

**Done when:** tests show opening 12 items keeps the last 10 newest first, re-opening one moves it to the front without a duplicate, and another Shop's recents are not shown.

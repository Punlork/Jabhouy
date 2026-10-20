# P4 Step 6: Add / edit Credit (canvas ៩, ៩ខ, ១០)

Status: open
Blocked by: 27, 28, 29

- Customer button opens the picker (no typed name). Lines list with QtyStepper and totals; `បន្ថែមទំនិញពីបញ្ជីតម្លៃ` opens the item picker. Amount: read-only `គណនាពីទំនិញ` with lines, typed MoneyInput without; ៛/$ switch re-converts with the snapshot; converted value under it. DateTimeField `ថ្ងៃ និងម៉ោងជំពាក់` (now on add), optional `ត្រូវសង`, status SegmentedControl, note, sticky `រក្សាទុក`.

**Done when:** 2 × ដប + 5 × គីឡូ saves 25,000 ៛; editing keeps the original rate snapshot; a Credit with no lines saves a typed amount or none.

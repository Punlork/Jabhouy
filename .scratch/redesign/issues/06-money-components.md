# Step 3: Money components

Status: open
Blocked by: 03, 05

- MoneyInput: numeric field with a `៛ | $` toggle; riel whole numbers with separators, dollars up to 2 decimals; `≈` converted hint below. No mic.
- PriceDisplay: price in its own currency, muted `≈` line when `showConverted` is on, amber `មិនទាន់មានតម្លៃ` when null — never `0 ៛`.

**Done when:** widget tests show null renders `មិនទាន់មានតម្លៃ`, and typing `7.5` in $ mode shows `≈ 30,000 ៛` at 4,000.

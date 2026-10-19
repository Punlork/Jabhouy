# Shop Price App – Redesign Implementation Plan

> **For Claude Code.** This document describes a full redesign of an existing mobile app built for family-run shops in Phnom Penh to look up product prices and track customer credit. Read the whole plan first, then start with **Phase 0** (inspect the repo). Work phase by phase; do not skip ahead.
>
> Design reference (canvas with every screen): https://claude.ai/artifact/7yB2Q6kx5udyawUJUPNZc2

---

## 0. Context and goals

The app has two parts:

1. **ហាង (Shop)** – a shared price list so any family member can find an item's price without asking the owner.
2. **ជំពាក់ (Credit)** – a record of customers who took goods on credit (the current app calls this "Loaner").

The app is published in the store, but **the developer is currently the only user**. There is no real user data to preserve, so this is a **clean start**: new schema, new API, no migration and no backward compatibility (see §3.5).

### Problems this redesign fixes

- Items with several prices (bottle vs case, kilo vs sack) are entered as **separate items**, or the prices are **typed into the item name** with the price left at `0 ៛`.
- "Single / Pack" controls appear twice on the add form and confuse people.
- Price names (Customer / Seller / Cost) are unclear.
- The home grid shows ~4 items per screen, mostly grey placeholder tiles.
- Credit entries often have **amount 0** with the items written only in the note.
- Credit dates are date-only and display a fake **07:00 AM** (midnight UTC shown in UTC+7).
- Sign-in / sign-up use a separate dark style, a hard-to-find sign-up link, no password reset, and there is no way for family members to share one shop.
- Edit/delete on credit entries is hidden behind a swipe.

### Design principles (apply everywhere)

- **Lookup speed first.** The home list is the most-used screen; a price should be findable in ~3 seconds.
- **Khmer first.** All UI copy is Khmer (see §4). Item names may be Khmer, English, or mixed.
- **Never show `0 ៛` for a missing price.** Show `មិនទាន់មានតម្លៃ` in amber instead.
- **Two currencies, one source of truth.** Every price is entered in riel (៛) or US dollars ($); the other currency is always calculated from the shop's exchange rate, never typed twice.
- **Optional things are marked optional**, not required things marked with `*`.
- **Encourage, don't force** (categories, photos, extra prices).
- **Tap, don't swipe**, for important actions.

---

## Phase 0 – Inspect before changing anything

1. Identify the stack (framework, state management, navigation, API client, backend language/DB).
2. Map existing screens to the new ones in §5 and list them back to me.
3. Find the current data models for items and loaners, and the API endpoints that serve them.
4. Check how dates are stored and displayed (expect the UTC/UTC+7 bug above).
5. Check the current auth setup (Google sign-in, username/password) and whether data is scoped per user or per shop.
6. Report findings and a short file-level plan **before** writing code. Ask about anything that conflicts with this document.

---

## 1. Design tokens

Implement these as a single theme/tokens file; no hard-coded colors or sizes in screens.

### Colors

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F4F4F2` | #121212 | App background |
| `surface` | `#FFFFFF` | #1C1C1C | Cards, inputs, sheets |
| `surfaceMuted` | `#E8E8E5` | #2A2A2A | Search field, inactive chips, image placeholders |
| `surfaceSubtle` | `#EDEDEA` | #242424 | Segmented control track, neutral tags |
| `border` | `#D6D6D3` | #3A3A3A | Input borders |
| `divider` | `#EEEEEB` | #262626 | List row dividers |
| `dividerStrong` | `#E2E2DF` | #303030 | Bottom bars, sticky footers |
| `textPrimary` | `#1F1F1F` | #EDEDEA | Main text, primary buttons, active chips |
| `textSecondary` | `#3A3A3A` | #D0D0CC | Labels |
| `textMuted` | `#5C5C5C` | #A3A3A0 | Hints, secondary info |
| `placeholder` | `#686866` | #959592 | Input placeholders |
| `scrim` | `#8E8E8A` | black 60% | Behind bottom sheets (or black at ~45% opacity) |
| `warningBg` / `warningText` | `#FCEFD8` / `#6B4200` | #3D2E10 / #F5C977 | Missing price, unpaid |
| `successBg` / `successText` | `#E2F0E4` / `#1E5B2A` | #1A3320 / #9AD3A5 | Paid |
| `dangerText` / `dangerBorder` | `#A12626` / `#E4B4B4` | #F09090 / #6B2C2C | Delete buttons |
| `onPrimary` | `#FFFFFF` | #1F1F1F | Text on dark buttons |

### Typography

- Font: **Kantumruy Pro** (bundled; supports Khmer + Latin), weights 400/500/600/700. No fallback font is bundled.
- Line height **1.5** globally (Khmer needs room for stacked vowels/subscripts).
- Sizes: page title 20/600 · section title 16/700 · body & inputs 16/400 · labels 15/500 · hints 13–14/400 · prices in lists 17/700 · big amounts 26–28/700.
- Inputs must be **16 px minimum** (prevents iOS zoom).

### Shape and spacing

- Radius: inputs 12 · cards/list groups 16 · bottom sheets 24 (top corners) · pill buttons fully rounded · chips 19–20.
- Heights: inputs 50 · primary buttons 54 · chips 38–40 · **every tap target ≥ 44×44**.
- Screen padding 16–20; section gap 24; field gap 6 (label→input).

### Icons

Simple 2px-stroke line icons (Lucide-style): back, close, search, mic, camera, calendar, clock, lock, plus, trash, pencil, check, chevron, shop, book.

---

## 2. Reusable components

Build these first, then compose screens from them.

- **AppBottomNav** – two tabs `ហាង` / `ជំពាក់`; active tab = dark pill with icon + label. Plus a floating extended button above it, right-aligned, whose label depends on the tab (`បន្ថែមទំនិញ` / `បន្ថែមការជំពាក់`).
- **SearchField** – muted background, search icon, optional mic button.
- **FilterChips** – horizontally scrollable; active = dark, inactive = muted. Supports a special **warning chip** (amber, with count badge).
- **LabeledField** – label above input (never placeholder-only labels), optional `(មិនចាំបាច់)` suffix, optional hint below, optional trailing mic or currency `៛`.
- **QuickPickChips** – row of tappable suggestion chips that fill a field.
- **PriceRowEditor** – one price row: `លក់ជា` (unit) · `ចំនួន` (pack count, optional, prefixed `×`) · `តម្លៃលក់` (selling price + `៛`) · remove button; plus, depending on shop settings, `តម្លៃលក់ដុំ` and `តម្លៃដើម` (lock icon) below.
- **MoneyInput** – numeric input with a small `៛ | $` toggle at the trailing edge. Riel: whole numbers with thousands separators. Dollar: up to 2 decimals. Under the field, a muted converted hint (`≈ $7.50` or `≈ 30,000 ៛`).
- **PriceDisplay** – main line shows the price in the currency it was entered in (`30,000 ៛` or `$7.50`); a smaller muted line shows the converted value when the shop setting `show_converted` is on. Shows amber `មិនទាន់មានតម្លៃ` when empty/null.
- **StatusPill** – `មិនទាន់សង` (warning colors) / `សងរួច` (success colors).
- **QtyStepper** – `− n +`, dark when selected.
- **BottomSheet** – drag handle, title, close button, content, optional sticky footer.
- **SegmentedControl** – two options on a muted track, selected = white with subtle shadow.
- **DateTimeField** – two buttons side by side: 📅 date, 🕐 time; each opens its own picker. Empty time shows grey `បន្ថែមម៉ោង`.
- **VoiceInputSheet** – see §5.6.

---

## 3. Data model and backend

### 3.1 Items and prices

```
Item           id, shop_id, name, category_id?, photo_url?, note?, created_at, updated_at
PriceOption    id, item_id, unit_name, pack_qty?, currency: KHR | USD,
               price_minor?, wholesale_minor?, cost_minor?, sort_order
PriceHistory   id, price_option_id, field, old_value, new_value, changed_by, changed_at
```

- One item has **one or more** price options. A pack is just an option with `pack_qty` (e.g. `កេះ`, 24). There is **no** separate variant/pack table and **no** Single/Pack type field.
- Prices are nullable: null = missing (shown as `មិនទាន់មានតម្លៃ`), never stored as 0 for "unknown".
- One currency per price option: selling, wholesale and cost of the same row share it.

### 3.1a Money rules (KHR + USD)

- **Store money as integers in minor units**: KHR = whole riel, USD = cents. Never use floats for money.
- **Exchange rate** lives in shop settings as `khr_per_usd` (integer, e.g. 4000 or 4100 – the shop chooses; pre-fill a suggestion but let the owner confirm).
- **Conversion** is done in one shared function on the backend and mirrored in the client:
  - USD → KHR: `round_to_100(cents * khr_per_usd / 100)` (riel rounds to the nearest 100 ៛, the smallest note in common use).
  - KHR → USD: `round_to_cent(riel / khr_per_usd)`; display with 2 decimals.
- Converted values are **display only** for items. They are never saved back as prices.
- Changing the exchange rate updates every converted display immediately, but does **not** change stored prices or past credit records.
- Write a `PriceHistory` row on every price change.

### 3.2 Categories and units

```
Category       id, shop_id, name, sort_order, hidden
CategoryUnit   id, category_id, unit_name, usage_count, hidden
```

- Seed each new shop with starter categories, each with typical units, for example: ភេសជ្ជៈ (ដប, កំប៉ុង, កេះ) · អង្ករ (គីឡូ, បេ) · មី (កញ្ចប់, កេស) · សាប៊ូ/អនាម័យ (ដុំ, ដប, កញ្ចប់) · នំ/ចំណី · ទឹកដោះគោ · ស្រា/ស្រាបៀរ · គ្រឿងទេស · ប្រេងឆា · បារី · ផ្សេងៗ. Keep the starter list around 10.
- A unit typed in the form that isn't in the list is added to that category's units automatically. Sort chips by `usage_count`.
- Units in use can be **hidden**, never deleted.

### 3.3 Users, shops, members and settings

```
User           id, display_name, email?, username?, password_hash?, google_id?, created_at
Shop           id, name, owner_id, created_at
Member         shop_id, user_id, role: owner | editor | viewer, joined_at
Invite         id, shop_id, code (6 chars, unambiguous: no 0/O/1/I), role: editor | viewer,
               created_by, expires_at (24 h), used_by?, used_at?, revoked_at?
```

- **Every** business table (items, categories, customers, credits, settings) carries `shop_id`, and every query is scoped by the caller's membership. Build this in from day one even while there is only one shop – adding it later is painful.
- A user can belong to more than one shop (later: a shop switcher); for now assume one active shop per user.
- Invite codes are single-use and expire after 24 h; the QR encodes the same code.


```
ShopSettings   shop_id, use_wholesale_price (bool), use_cost_price (bool),
               default_currency: KHR | USD, khr_per_usd (int), show_converted (bool),
               rate_updated_at, rate_updated_by
```

- Selling price is always on. Wholesale and cost fields appear in **every** price row only when enabled.
- **Cost price is visible to the owner only.**
- Only owner/editor can change prices or category/unit lists.

### 3.4 Credit

```
Customer       id, shop_id, name, phone?, note?
Credit         id, shop_id, customer_id?, customer_name, currency: KHR | USD, amount_minor?,
               khr_per_usd_snapshot (int), status: unpaid | paid,
               taken_at (timestamptz), due_date (date)?, note?,
               created_by, created_at, updated_at, paid_at?
CreditLine     id, credit_id, price_option_id?, item_name, unit_name, qty,
               currency: KHR | USD, unit_price_minor, line_total_minor
```

- `taken_at` is a **full timestamp stored in UTC**, displayed in `Asia/Phnom_Penh`.
- `CreditLine` stores a **snapshot** of name/unit/price at the time of credit, so later price changes don't alter old debts.
- `amount_minor` defaults to the sum of lines but can be overridden manually.
- A credit has **one currency** (the shop default, switchable in the form). Lines priced in the other currency are converted into the credit currency using `khr_per_usd_snapshot` – the rate **at the time the credit was created** – so old debts never change when the shop updates its rate.
- The list and details always show the other currency too (`25,000 ៛ · ≈ $6.25`), because customers often pay in either.

### 3.5 Clean start (no migration)

The developer is the only user, so:

1. Export the current data to CSV as a backup (5 minutes, just in case).
2. Drop the old tables and create the new schema in §3.1–3.4.
3. Replace the old API completely – no versioning, no compatibility layer.
4. Release the new backend and the new app together.
5. Re-enter any real shop items through the new add-item form (this doubles as a real-world test of the design).

### 3.6 Auth

- **Google sign-in** (primary) and **username-or-email + password** (secondary). Hash passwords with a standard algorithm (bcrypt/argon2).
- **Password reset by email** (`ភ្លេចលេខសម្ងាត់?`). Users who signed up with a username only and no email cannot reset – make email required for password sign-ups.
- After sign-in: if the user has no shop → Shop choice (§5.8); otherwise → Home.

---

## 4. Copy (Khmer strings)

Put all strings in a localization file. Key strings:

| Key | Khmer |
|---|---|
| tab.shop / tab.credit | ហាង / ជំពាក់ |
| item.add / item.edit / item.save | បន្ថែមទំនិញ / កែទំនិញ / រក្សាទុក |
| item.name | ឈ្មោះទំនិញ |
| item.photo | រូបថត |
| price.section | តម្លៃ |
| price.unit / price.count / price.selling | លក់ជា / ចំនួន / តម្លៃលក់ |
| price.wholesale / price.cost | តម្លៃលក់ដុំ / តម្លៃដើម |
| price.add | បន្ថែមតម្លៃ |
| price.missing | មិនទាន់មានតម្លៃ |
| price.edit | កែតម្លៃ |
| common.optional | (មិនចាំបាច់) |
| common.delete / common.cancel / common.all | លុប / បោះបង់ / ទាំងអស់ |
| category / category.choose / category.new | ប្រភេទ / ជ្រើសរើសប្រភេទ / បង្កើតប្រភេទថ្មី |
| category.suggested | បានណែនាំតាមឈ្មោះ · ចុចដើម្បីប្តូរ |
| note | កំណត់ចំណាំ |
| search.items / search.customers | ស្វែងរកទំនិញ / ស្វែងរកអតិថិជន |
| credit.add / credit.edit | បន្ថែមការជំពាក់ / កែការជំពាក់ |
| credit.customer / credit.choose | អតិថិជន / ជ្រើសរើស |
| credit.items / credit.addItems | ទំនិញដែលយក / បន្ថែមទំនិញពីបញ្ជីតម្លៃ |
| credit.amount / credit.amountHint | ចំនួនទឹកប្រាក់ / គណនាពីទំនិញ · អាចកែបាន |
| credit.takenAt / credit.dueDate | ថ្ងៃ និងម៉ោងជំពាក់ / ត្រូវសង |
| credit.unpaid / credit.paid | មិនទាន់សង / សងរួច |
| credit.markPaid | សម្គាល់ថាសងរួច |
| credit.totalOwed | នៅជំពាក់សរុប |
| credit.noAmount | មិនទាន់មានចំនួន |
| picker.title / picker.addToCredit | ជ្រើសទំនិញ / បន្ថែមទៅការជំពាក់ |
| voice.speakingInto / voice.listening / voice.use | កំពុងបញ្ចូលទៅ / កំពុងស្តាប់… / ប្រើអត្ថបទនេះ |
| settings.title / settings.pricesUsed | ការកំណត់ហាង / តម្លៃដែលហាងប្រើ |
| settings.currency | រូបិយប័ណ្ណ |
| settings.defaultCurrency | រូបិយប័ណ្ណលំនាំដើម |
| settings.rate | អត្រាប្តូរប្រាក់ |
| settings.rateFormat | $1 = {rate} ៛ |
| settings.showConverted | បង្ហាញតម្លៃជារូបិយប័ណ្ណទាំងពីរ |
| currency.khr / currency.usd | រៀល / ដុល្លារ |
| auth.welcome / auth.welcomeSub | សូមស្វាគមន៍ / ចូលដើម្បីមើលតម្លៃហាងរបស់អ្នក |
| auth.google | បន្តជាមួយ Google |
| auth.or | ឬ |
| auth.userOrEmail | ឈ្មោះអ្នកប្រើ ឬអ៊ីមែល |
| auth.password | លេខសម្ងាត់ |
| auth.username | ឈ្មោះអ្នកប្រើ |
| sync.noPermission | អ្នកលែងមានសិទ្ធិកែ |
| auth.signIn / auth.signUp | ចូល / ចុះឈ្មោះ |
| auth.noAccount / auth.haveAccount | មិនទាន់មានគណនី? / មានគណនីរួចហើយ? |
| auth.createAccount / auth.createSub | បង្កើតគណនី / ប្រើ Google ដើម្បីចាប់ផ្តើមលឿនជាងគេ |
| auth.name / auth.email / auth.pwHint | ឈ្មោះ / អ៊ីមែល / យ៉ាងតិច ៨ តួអក្សរ |
| auth.signOut | ចេញពីគណនី |
| shop.hello / shop.noShop | សួស្តី {name} / អ្នកមិនទាន់នៅក្នុងហាងណាមួយទេ។ ជ្រើសមួយ៖ |
| shop.join / shop.joinSub | ចូលរួមហាង / សម្រាប់សមាជិកគ្រួសារ · ស្កេន QR ឬវាយលេខកូដ |
| shop.create / shop.createSub | បង្កើតហាងថ្មី / សម្រាប់ម្ចាស់ហាង |
| shop.name / shop.starterCats | ឈ្មោះហាង / ប្រភេទចាប់ផ្តើម |
| shop.createBtn / shop.joinBtn | បង្កើតហាង / ចូលរួម |
| join.scan / join.code | ស្កេន QR ពីទូរស័ព្ទម្ចាស់ហាង / វាយលេខកូដអញ្ជើញ |
| invite.title / invite.role | អញ្ជើញសមាជិក / សិទ្ធិរបស់អ្នកចូលរួម |
| role.viewer / role.editor / role.owner | មិនអាចកែតម្លៃ / អាចកែតម្លៃ / ម្ចាស់ហាង |
| invite.expires / invite.share | ផុតកំណត់ក្នុង ២៤ ម៉ោង / ចែករំលែកលេខកូដ |
| members | សមាជិក |

Time format: `16 តុលា 2026` and `11:05 ព្រឹក` (ព្រឹក / រសៀល / ល្ងាច / យប់).

Money format: riel = grouped digits + ` ៛` (`30,000 ៛`); dollar = `$` + 2 decimals (`$7.50`); converted values are prefixed with `≈` and shown muted (`≈ $7.50`).

---

## 5. Screens

Numbers match the canvas titles.

### 5.1 Home – list (១) and grid (១ក)

- Top: SearchField, grid/list toggle, settings button.
- FilterChips: `ទាំងអស់`, then the **warning chip** `មិនទាន់មានតម្លៃ (n)` (only when n > 0 and user can edit; filters to items with any missing price), then categories.
- **No banner.**
- List row: 48 px thumbnail (photo or first letter), name (wraps), then **one line per price option**: unit on the left (`1 ដប`, `1 កេះ · ×24`), PriceDisplay right-aligned and bold, with the converted value in small muted text under it when `show_converted` is on.
- Grid card: shorter image area, name clamped to 2 lines, same price lines. Default to **list**; remember the user's choice.
- Tap row/card → Item details sheet.
- AppBottomNav with `បន្ថែមទំនិញ`.

### 5.2 Item details sheet (២)

Bottom sheet: thumbnail, name, category tag, close. One block per price option: `1 {unit} · ×{qty}` and big price; below it `លក់ដុំ` and `ដើម` (lock, owner only), `—` when empty. Then `កែចុងក្រោយ {date} ដោយ {name}`. Buttons: `កែតម្លៃ` (primary) → Edit item; `លុប` (danger outline, confirm first).

### 5.3 Edit item (៣) / Add item (៤, ៤ក)

Same form for add and edit:

1. **Photo (96×96) + item name** side by side; mic in the name field.
2. **Category**: QuickPickChips of top categories + `ទាំងអស់ ›` (opens 5.5). Auto-suggest from the name with simple keyword rules (e.g. name contains `អង្ករ` → អង្ករ, `ទឹក` → ភេសជ្ជៈ) and show the suggested hint. Pre-select the last used category otherwise. Not required.
3. **Prices**: header row of column labels, then PriceRowEditor rows. Each row's price uses MoneyInput (៛/$ toggle, defaulting to the shop's default currency); wholesale and cost follow the row's currency. Unit QuickPickChips below the first row, filtered by the chosen category (pre-fill the most common unit). `+ បន្ថែមតម្លៃ (ឧ. កេះ ×24, បេ)` adds a row. Wholesale/cost appear per row according to shop settings – **no toggle**.
4. **Note** (optional) with mic.
5. Sticky footer: `រក្សាទុក`.

Validation: name required; at least one price row with a unit or price. A row with no price saves as missing (null), not 0.

### 5.4 Credit

- **Credit list (៧)**: SearchField (customers); dark summary card (`នៅជំពាក់សរុប`, total of unpaid known amounts in the shop default currency with the other currency below, count unpaid, count without amount); FilterChips `មិនទាន់សង` (default) / `សងរួច` / `ទាំងអស់`; rows show name, amount or `មិនទាន់មានចំនួន`, one-line note preview, StatusPill, date. Tap → details. Nav button `បន្ថែមការជំពាក់`.
- **Credit details sheet (៨)**: name, StatusPill, date/time; amount box; items (if any) and note; primary `សម្គាល់ថាសងរួច` (sets status + `paid_at`); `កែ` and `លុប`.
- **Add credit (៩, empty) / with items (៩ខ) / Edit (១០)**:
  1. Customer: text field with mic + `ជ្រើសរើស` (opens 5.4 customer picker). Typing a new name creates the customer on save.
  2. `ទំនិញដែលយក (មិនចាំបាច់)`: list of CreditLines (name, `1 unit · price`, QtyStepper, line total) + `បន្ថែមទំនិញពីបញ្ជីតម្លៃ` → Item picker.
  3. Amount: MoneyInput in the credit currency; auto-sum of lines (`គណនាពីទំនិញ · អាចកែបាន`), or typed manually when there are no lines. Show the converted value under it. Switching ៛/$ re-converts the total using the rate snapshot.
  4. DateTimeField `ថ្ងៃ និងម៉ោងជំពាក់` (defaults to now on add); optional `ត្រូវសង` (date only).
  5. Status SegmentedControl; note with mic; sticky `រក្សាទុក`.
- **Item picker (៩ក)**: tall sheet; SearchField with mic; category chips; each item lists **every price option as its own row** with a `+` button that turns into a QtyStepper; selected rows highlighted; sticky footer with `បានជ្រើស n មុខ`, running total, and `បន្ថែមទៅការជំពាក់`.
- **Customer picker (១១)**: sheet with search, rows showing name + current balance (`ជំពាក់ 23,000 ៛` / `សងរួច`), and `បន្ថែមអតិថិជនថ្មី`.

### 5.5 Category picker (៥)

Sheet: title, search, radio list of categories (selected = bold + check), `បង្កើតប្រភេទថ្មី` at the bottom.

### 5.6 Voice input (៦)

- Mic buttons only on **free-text fields**: item name, credit customer name, notes, search. **Never on number/price fields.**
- Tap → bottom sheet: `កំពុងបញ្ចូលទៅ {field label}`, ខ្មែរ/EN toggle (default ខ្មែរ, `km-KH`), live waveform driven by mic volume, `កំពុងស្តាប់…` with red dot, live transcript in large text, buttons `បោះបង់` / `ប្រើអត្ថបទនេះ`. Nothing is written to the field until confirmed.
- Use the platform recognizer (Android `SpeechRecognizer` with `km-KH`). Check Khmer availability on iOS at runtime (`SFSpeechRecognizer.supportedLocales()`); if unavailable, hide the ខ្មែរ option or fall back to a cloud service. Handle no-internet and permission-denied states gracefully.

### 5.7 Shop settings (១២)

- `តម្លៃដែលហាងប្រើ`: three tick-box rows – `តម្លៃលក់` (always on, disabled), `តម្លៃលក់ដុំ`, `តម្លៃដើម` (`មើលឃើញតែម្ចាស់ហាង`). Owner only.
- `រូបិយប័ណ្ណ` (owner only): default currency (៛ / $ segmented control); exchange rate field shown as `$1 = [4,000] ៛` with `កែចុងក្រោយ {date} ដោយ {name}` under it; tick box `បង្ហាញតម្លៃជារូបិយប័ណ្ណទាំងពីរ`. Saving a new rate asks for confirmation and explains that old credit records keep their original rate.
- Links: `ប្រភេទ និងឯកតា` (add/rename/hide/reorder categories and their units), `សមាជិក និងសិទ្ធិ` (→ Invite & members, §5.8).

### 5.8 Sign in, sign up and shop onboarding (១៣–១៨)

- **Sign in (១៣)**: light theme; logo, `សូមស្វាគមន៍`, subtitle; full-width dark `បន្តជាមួយ Google` on top; `ឬ` divider; `ឈ្មោះអ្នកប្រើ ឬអ៊ីមែល`; password with show/hide and `ភ្លេចលេខសម្ងាត់?` beside its label; outlined `ចូល`; footer `មិនទាន់មានគណនី? ចុះឈ្មោះ`.
- **Sign up (១៤)**: back button; same layout; name, email, password (hint `យ៉ាងតិច ៨ តួអក្សរ`); outlined `បង្កើតគណនី`; footer `មានគណនីរួចហើយ? ចូល`.
- **Shop choice (១៥)**: shown after sign-in when the user has no shop. Greeting + two large cards: `ចូលរួមហាង` (first – most users are family members) and `បង្កើតហាងថ្មី`; `ចេញពីគណនី` at the bottom.
- **Create shop (១៦)**: shop name; default currency segmented control; exchange rate `$1 = [4,000] ៛` (hint: changeable later); starter categories as pre-selected chips (tap to remove); sticky `បង្កើតហាង`. Creates `Shop`, owner `Member`, `ShopSettings`, and seeds categories/units.
- **Join shop (១៧)**: camera viewfinder to scan the owner's QR; `ឬ`; six single-character boxes for the invite code (auto-advance, paste support, uppercase); hint where the owner finds the code; `ចូលរួម`. Errors: invalid, expired, already used.
- **Invite & members (១៨, owner only)**: role segmented control (`មើលតែប៉ុណ្ណោះ` / `អាចកែតម្លៃ`) chosen **before** generating; QR + large code + expiry; `ចែករំលែកលេខកូដ` (system share sheet – Telegram etc.); members list with role; tap a member to change role or remove.

---

## 6. Navigation map

```
Sign in ⇄ Sign up ──(no shop)──▶ Shop choice ──▶ Create shop ──▶ Home
                  │                          └──▶ Join shop ───▶ Home
                  └──(has shop)──▶ Home

Home (list/grid) ──tap item──▶ Item details sheet ──កែតម្លៃ──▶ Edit item
      │                                             └─លុប──▶ confirm
      ├─ បន្ថែមទំនិញ ──▶ Add item ──▶ Category picker / Voice sheet
      ├─ settings ──▶ Shop settings ──▶ Categories & units / Invite & members
      └─ tab ជំពាក់ ──▶ Credit list
                          ├─tap row──▶ Credit details sheet ──កែ──▶ Edit credit
                          │                                 └─សម្គាល់ថាសងរួច
                          └─ បន្ថែមការជំពាក់ ──▶ Add credit
                                                  ├─ ជ្រើសរើស ──▶ Customer picker
                                                  └─ បន្ថែមទំនិញពីបញ្ជីតម្លៃ ──▶ Item picker
```

---

## 7. Phases and acceptance criteria

Owner in brackets: **app** = you, **API** = Sokheng. Phases 1 and 2 run in parallel once Phase 0 is agreed.

**Phase 0 – API contract [app, API reviews].** `.scratch/redesign-api/spec.md`: entities, upsert by UUID, per-shop pull of changes with tombstones, server `updated_at`, 403 rule, shop/member endpoints, time and money formats. *Done when:* Sokheng agrees to it.

**Phase 1 – Foundations [app].** Light and dark tokens, bundled Kantumruy Pro, localization, components (§2), money conversion and formatting in `jabhouy_core`. *Done when:* components render in Khmer with line height 1.5 in both themes, every tap target ≥ 44 px, and conversion tests pass ($7.50 → ≈ 30,000 ៛ and 3,800 ៛ → ≈ $0.95 at 4,000; $1.23 → 4,900 ៛).

**Phase 2 – Backend clean start [API].** CSV backup, new schema (§3, decisions 21–27), `Shop` / `Member` / `ShopSettings`, membership and role checks. *Done when:* every endpoint rejects a non-member; a viewer cannot change prices, categories, units or settings, or delete a Credit or Customer, but can add and edit Credits; the same upsert sent twice gives one row; a pull returns deletes as tombstones.

**Phase 2b – Auth and one shop [app + API].** The shop is created by a Better Auth `user.create.after` hook on the server (removed in Phase 7). Redesigned sign in / sign up with Username, Choose Username for Google, Profile under Settings, one shop created for a user with none. *Done when:* a new Google user picks a Username and lands on an empty, working Home; a password sign-up with Username and email works.

**Phase 3 – Shop [app].** Home list/grid, item sheet, add/edit with Price options, categories/units, shop settings, role-based UI. *Done when:* an item with ដប + កេះ ×24 is created in one form and shows as one row with two prices; no screen shows `0 ៛`; two phones editing the same item offline end with the later save.

**Phase 3b – Currency [app].** MoneyInput, dual PriceDisplay, currency settings. *Done when:* changing the rate updates every `≈` value and no stored price.

**Phase 4 – Credit [app].** List, details, add/edit with item picker and auto-total, customer picker with rename/delete, date + time. *Done when:* 2 × ដប (3,000) + 5 × គីឡូ (3,800) = 25,000 ៛ (≈ $6.25 at 4,000); a USD line converts per line with the snapshot; changing the rate afterwards changes neither that Credit nor the summary total; times are stored in UTC and display in UTC+7; a Customer with Credits cannot be deleted.

**Phase 5 – Voice [app].** *Done when:* Khmer dictation works on a real Android device and nothing is inserted without confirmation.

**Phase 6 – Release, solo [app + API].** Deploy the backend and release the app together; the phone resets on schema 9 (keeps `BankNotifications`). Use it in one shop and fix what feels slow.

**Phase 7 – Family sharing [app + API].** Invites, screens ១៥–១៨, role change and removal. *Done when:* a second phone joins as viewer by QR, sees prices (cost included), cannot edit prices, and can add a Credit; switching it to editor allows editing without re-joining; a User in two Shops switches between them from Settings and each shows only its own data; a price edit made offline after demotion is dropped with `អ្នកលែងមានសិទ្ធិកែ`; removing the member wipes the shop from that phone.

## 8. Do not

- Do not store or display `0` for an unknown price or amount.
- Do not reintroduce a Single/Pack toggle or separate variant/pack types.
- Do not show a persistent "missing prices" banner on the home screen.
- Do not enforce roles in the client only – the backend rejects what a role cannot do.
- Do not put mic buttons on number fields.
- Do not write any query without scoping it to the caller's shop.
- Do not use floating-point numbers for money, and do not store converted prices.
- Do not recalculate old credits when the exchange rate changes.

## 9. Open decisions (ask me)

1. Starter category and unit lists (to confirm with the shop families).
2. Who counts as editor vs viewer in each family shop.
3. The default exchange rate to pre-fill for new shops.
4. Whether anything from the current data should be re-entered after the clean start.

---

## Decisions from review (2026-10-16)

These override the sections above where they conflict. Background: `docs/adr/0001-offline-first-shared-shops.md`, terms in `GLOSSARY.md`.

1. Offline-first stays: last write wins per row on server `updated_at`; UUIDv7 IDs made on the phone.
2. Cost price is visible to every Member; it stays a column on `PriceOption` (drop the owner-only rules in §3.3, §5.2, §5.7, Phase 2/7 criteria, §8).
3. Terms: Credit, Credit item, Customer. Rename Loaner code during the clean start.
4. Income is off in every flavor, code untouched, and its table survives the clean start.
5. No password reset: remove `ភ្លេចលេខសម្ងាត់?`. Username and email required (Better Auth's `user.email` is not null); email stays unverified. Google primary.
6. The app owner writes the API contract in `.scratch/redesign-api/spec.md`; the API owner implements it. Phase 0 "identify the stack" is replaced by that spec.
7. Ship in plan order, voice and two currencies included.
8. Credit is paid or unpaid only; partial payments are an amount edit plus a note.
9. A Credit with lines has amount = sum of lines, not editable (`គណនាពីទំនិញ`); amount is typed only with no lines.
10. Every Credit has a Customer chosen in the customer picker; new Customers are created only there. Drop `customer_name` and typed-name auto-create.
11. 403 on a queued write: drop it, re-pull the row, show `អ្នកលែងមានសិទ្ធិកែ`. Removed Member's phone wipes that Shop's data.
12. Drop `PriceHistory`; items carry `updated_by` / `updated_at`.
13. Drop `CategoryUnit.usage_count`; order unit chips by counting Price options on the phone.
14. Every Member can add, edit and mark Credits paid; only owner and editors delete them.
15. Dark mode stays: every token in §1 gets a dark value; screens are checked in both themes.
16. Components live in `packages/jabhouy_ui`; BottomSheet (`AppSheet`) builds on `AppBottomSheet`; LabeledField is a label + hint around any input child (not a `CustomTextFormField` wrapper, whose floating label clashes); StatusPill replaces the paid/unpaid icons. Tokens replace `AppColorTheme` outright.
17. Kantumruy Pro is the only bundled font (Noto Sans Khmer removed), never fetched by `google_fonts` at runtime.
18. Money conversion, rounding and formatting live in `jabhouy_core` (pure Dart, `dart test`); MoneyInput and PriceDisplay only call them.
19. Voice (Phase 5) adds a speech dependency; none is installed today.
20. Dark tokens are the Dark column in §1 (contrast checked against WCAG AA).
21. Better Auth owns `user`, `account`, `session`; do not hand-build `User`. New tables (`Shop`, `Member`, `Invite`, `ShopSettings`) reference Better Auth's `user.id`.
22. D1 has no `timestamptz`: `taken_at` is UTC (format fixed in the API spec); `due_date` is date-only via `toIsoDate()`.
23. Every synced table carries server-set `updated_at`, `updated_by`, and a `deleted_at` tombstone.
24. Creating and redeeming invites needs internet; it is the one action that does not work offline.
25. A unit's identity is `(category_id, unit_name)`; the server merges duplicate units added offline.
26. Phone schema: version 9 adds the new tables (singular SQL names matching the API) next to the old ones, so current screens keep working; version 10, at release, drops the old business tables and clears the outbox and sync cursors, keeping `BankNotifications`.
27. Price options sync inside their Item, and Credit items inside their Credit: one sync entity per parent, the server replaces the child set, and the later save of the whole parent wins.
28. §3.3 split: `shop_id`, `Shop`, `Member` (role), `ShopSettings` and auto-create in Phases 2/2b; `Invite`, screens ១៥–១៨, role change and removal in Phase 7.
29. Navigation (§6) adds: Sign in → (new Google User) Choose Username → Home; Settings → Profile (name, Username, `ចេញពីគណនី`); Settings → app diagnostics behind `FEATURE_DIAGNOSTICS`. No forgot-password route; no income routes. Until Phase 7, "no shop" auto-creates one and goes to Home.
30. A Credit item priced in the other currency converts and rounds per item (to 100 ៛ or 1 cent) with the rate snapshot; the Credit amount is the sum of the rounded items.
31. §5 updates from earlier decisions:
    - 5.2: `ដើម` shows without a lock for every Member; `កែតម្លៃ` / `លុប` only for owner and editor; "last edited" from `updated_by` / `updated_at`.
    - 5.3: unit chips ordered by Price option count on the phone.
    - 5.4: Customer field is a button that opens the customer picker (no typed name, no mic); the mic moves to the new-customer name field in the picker. With lines, amount is read-only `គណនាពីទំនិញ`. `លុប` only for owner and editor.
    - 5.6: mic fields are item name, new-customer name, notes, search.
    - 5.7: no owner-only note on cost price.
    - 5.8: no `ភ្លេចលេខសម្ងាត់?`. Sign up asks name, Username, email, password (all required, as today). Sign in accepts Username or email.
32. Totals across currencies (credit summary card, customer balance) convert each Credit with its own rate snapshot, so totals never move when the shop rate changes.
33. Customers are renamed and deleted from the customer picker (✎ per row, reusing the current customer edit dialog). A Customer with any Credit cannot be deleted; delete is owner and editor only. The separate customer page and `customer_auto_complete_field` go away.
34. Phase 2b's shop is created on the server by a Better Auth `user.create.after` hook (Shop, owner Member, ShopSettings, starter categories in one transaction); Phase 7 removes the hook.
35. API naming: Item `prices` (each `unit`, `packQty`, `currency`, `price`, `wholesale`, `cost`); Credit `items` (`name`, `unit`, `qty`, `unitPrice`, `total`) and `khrPerUsd` (rate when made); money fields have no suffix and are whole numbers in riel or cents.
36. A User can belong to several Shops. Phase 7 adds a Shop switcher (Settings → sheet listing `/me` shops); the phone remembers the active `shopId`, keeps `shop_id` on every local table, and keeps one sync cursor per Shop. Switching does not wipe; removal wipes only that Shop. No multi-account switcher (one signed-in User per phone).
37. Password sign-up is off (`emailAndPassword.disableSignUp: true`) to stop spam accounts; password sign-in stays for existing accounts; new users join with Google only. Screen ១៤ (sign up) and its link are removed. iOS is not distributed now, so no iOS Google work is needed before release. Replaces the sign-up parts of decisions 5 and 31.
38. The viewer role is labelled `មិនអាចកែតម្លៃ` (can't edit prices), not "view only", because viewers can record Credits.
39. PriceRowEditor is built in Phase 3 inside `jabhouy_shop` (its only user), against the real Price option model; it is not a shared `jabhouy_ui` component.
40. One `ItemRepository` / `ItemDao` in `jabhouy_shop` covers Items, Price options, categories and units; the category model is `ItemCategory` (the old table owns `Category`). Packages read the Current Shop through `ShopScope` in core; its `syncs` is false for the stand-in Shop, so nothing is queued until the real `/me` is on.

## Decisions from the find-first update (2026-10-19)

The updated body (§3.1b, Phase 3a, new §5.1/§5.3 details, canvas ១–១ឃ, ៤ខ, ៤គ, ៣ក) adds find-first features. Decisions 1–40 still override it wherever it repeats older text.

41. Barcode uniqueness within a Shop is checked on the phone only (the item form blocks a duplicate). The server has no unique rule, so no Item save is lost; if an offline duplicate slips through, a scan lists every matching Item to pick from.
42. Search runs in memory on the phone: normalize (strip zero-width spaces, lowercase Latin), then rank exact → starts-with → nickname → contains → fuzzy. Fuzzy allows one wrong character and only for queries of 4+ characters.
43. Home on scroll down: the category FilterChips stay pinned at the top; search + scan, RecentPills and the list header slide away and return on a small scroll up.
44. Feature flags stay build-time (`config/features/<flavor>.json`). New flags: `FEATURE_BARCODE_SCAN` (scan button, scan result, row barcode button) and `FEATURE_VOICE_INPUT` (mic buttons, voice sheet); on in development, off in staging and production until proven on a real device. Search, nicknames, Recently viewed and currency get no flag.
45. Item `nicknames` is a JSON list column locally and an array in the API; PriceOption gains `barcode`. Phone schema 10 adds both columns; the release-time drop of old tables (decision 26) moves to schema 11.
46. Recently viewed: last 10 Items per Shop in a local, never-synced table, newest first, de-duplicated.
47. Barcode scanning uses `mobile_scanner` (offline, ML Kit on Android).
48. Phase order: 3 → 3a (find first) → 3b (currency; mostly done in Phase 1) → 4.
49. A duplicate item name is a warning, not an error (canvas ៤គ): `មានទំនិញឈ្មោះនេះរួចហើយ · មើល · ឬរក្សាទុកជាទំនិញថ្មី`.

Open: the unknown-barcode sheet (§3.1b attach / create) is not on the canvas; decide before building the scan flow.
50. Until the server seeds Shops (Phase 2b) and issue 16 can create categories, the stand-in Shop (`syncs == false`) gets §3.2's 11 starter categories on the phone when it has none. A server Shop is never seeded by the phone.
51. Quick add: an Item may be saved with a name only (no price row required); it counts as missing a price and waits under the `មិនទាន់មានតម្លៃ` chip. Pack count must be above 0 (`ចំនួនត្រូវធំជាង ០`), so `×1` is allowed. Form validation is: name required, count above 0, no decimals in riel, barcode not used by another Item.
52. Wholesale and cost fields in a price row use the underline style (canvas ៣ខ); the remove-row `✕` sits at the end of that line so the price field keeps room beside the `៛ $` switch.
53. An Item has one category (`categoryId`). Multiple categories were considered and declined: schema, API and sync cost for a rare need; nicknames and search cover cross-finding. Revisit as tags if real use shows items that belong in two places.
54. Unit chips show under every price row (not only the first, as §5.3 and canvas ៤ក draw them); the `ឯកតាសម្រាប់ «…»` hint shows once, under the first row.
55. The staging flavor is removed (Android flavor, iOS scheme and configurations, entrypoint, feature config, run scripts, fastlane lanes). Flavors are development and production. Play's `internal` lane now uploads the production build. Where earlier decisions say "off in staging and production", read "off in production".
56. One price row is open at a time; the others show as a one-line summary (`1 កេះ · ×12   12,222 ៛  ✎`, then wholesale/cost) that opens on tap. A new row opens; on save the first row with a problem opens. Column labels and unit chips show only in the open row (replaces decision 54's chips under every row).
57. Each price row has a header line with a chevron (`▾` closed, `▴` open) that toggles it; the open row keeps its header on top and can be closed, leaving none open. Still one open at a time. Refines decision 56.
58. The item note shows in the details sheet under the prices (`កំណត់ចំណាំ` + text), not on the Home list, which stays tuned for fast price lookup. No lock icon on `ដើម` anywhere (decision 2: every Member sees cost).

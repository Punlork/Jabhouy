# Shop item form

**Status:** Draft
**Author:** Punlork
**Updated:** 2026-09-28

## Summary

The shop item form keeps its variant flow and gets a layout that fits a phone: labels above fields, the required price on its own row, and variant cards that collapse to one summary line once filled.
Create and edit share the card, and differ in what the card may do: create holds several collapsible cards, edit holds exactly one that stays open.
A collapsed card still has to validate, and Flutter's `Form.validate()` only checks fields that are in the tree, so collapsing hides a card's fields rather than removing them, and each variant also checks itself in the form controller.
Prices stop being dropped without a word when they are not plain ASCII digits.

## Context

On a phone, the variant card squeezes three prices into one row, so the Khmer labels for customer and seller price both truncate to "តម្លៃសម្រាប់…" and read the same.
Error text truncates the same way, and a fixed field stays red until the next save.
With two or three variants the open cards fill a screen.

## How it works today

`ShopItemFormPage` holds one `Form`; `ShopItemVariantBuilder` draws a card per `ShopItemVariantDraft`; `ShopItemFormController` turns drafts into models.

| | Create | Edit |
| --- | --- | --- |
| Cards | starts with one single; chips add Single, Pack or Custom | exactly one; no chips, no ✕ (`allowMultiple: !isEditing`) |
| Card fields | variant name, pack size, customer / cost / seller price | same |
| Save | `buildNewItems`: one `ShopItemModel` per card | `buildEditedItem`: the first card only |
| Name written | `"<name> - <label> x<pack>"` | same, split back on open by `_splitEditableName` |

Variants are not a stored concept: each card becomes its own item, and pack size lives only in the name suffix, which `ShopItemModel.packAmount` reads back with `_packSuffixPattern`.
Custom is a single card with a free label.
Customer price is the one required price, as it was before the variant flow (`461b1a6^`).

Five things go wrong:

1. **Labels truncate.** Three prices share a row (`shop_item_variant_builder.dart`, the third `Row`), each about a third of the card, and the floating labels shrink further because the inputs are `isDense`.
2. **Errors truncate.** They have one line and a third of the width.
3. **Errors go stale.** The form sets no `autovalidateMode`, so a fixed field stays red until the next save.
4. **Bad prices vanish.** `parseControllerPrice` returns `null` for anything `int.tryParse` rejects — `1,500`, `1500.5`, Khmer digits `១៥០០` — and the item saves with no price and no error.
5. **Pack size shows on single cards,** as `1`, where it means nothing.

## Goals

- Every label and error on the card reads in full, in Khmer, on a phone.
- Correcting a field clears its error immediately.
- A price typed in Khmer digits saves as the same number; a price the form cannot read shows an error instead of saving nothing.
- On create, a filled card collapses to one line, and a card with a problem is never hidden at save.
- On edit, a single item can still become a pack and back.

## Non-goals

- **No stored variant grouping.** Cards still save as separate items; linking them needs a model and backend change.
- **No change to which price is required.** Customer price stays the only one.
- **No new pack-size field on the model.** It stays in the name suffix.

## Approach

### The card

```text
┌ [Single | Pack] ─────────────────── ⌃  ✕ ┐
│ Variant name                             │
│ [ Pack Can                             ] │
│ Items per pack                           │
│ [ 24                                can] │
│ Customer price *                         │
│ [ 400                                ៛ ] │
│ Cost price           Seller price        │
│ [              ៛ ]   [               ៛ ] │
└──────────────────────────────────────────┘
```

The sketch shows a Pack card.
A Single card has the same layout without the items-per-pack row; no label on screen says which rows depend on the type.
Every price is the price of the variant as sold: a pack's customer price is what the whole pack costs.

- Labels sit above each input, at body size, so Khmer script has room; inputs lose `isDense` floating labels.
- Customer price takes a full row; cost and seller share the next, where each label fits at half width.
- The header carries a Single/Pack toggle instead of repeating the variant name. Pack reveals items-per-pack; switching to Single clears it.
- Errors get `errorMaxLines: 2`.
- The `Form` uses `AutovalidateMode.onUserInteraction`.

### Prices and pack size

A shared input formatter maps Khmer digits U+17E0–U+17E9 to ASCII, then keeps digits only, so a pasted `1,500` becomes `1500`.
The validator rejects an empty customer price and a pack of fewer than 2.
`parseControllerPrice` keeps returning `null` for an empty optional price, which is now the only way to get one.

### What each draft knows about itself

`ShopItemVariantDraft.problems(l10n)` returns the draft's errors from its own text controllers, with no widget involved.
The collapsed summary, the ⚠ badge and expand-on-save all read it.
The field validators return the same messages, so the two cannot disagree.

### Create: several cards, collapsible

| Moment | Card |
| --- | --- |
| Added by a chip | opens expanded, focused on variant name |
| Another card added | every card with no problems collapses |
| Header tapped | toggles |
| Save pressed | cards with problems expand; the page scrolls to the first |

Collapsed, a card reads `Pack · Pack Can · ×24 · 400 ៛`, or `⚠ Pack · Pack Can · ×24 · no price`.
Collapsing wraps the fields in `Offstage` inside an `AnimatedSize`: they stay mounted, so `Form.validate()` still checks them.
Expansion state is view state on the draft (`isExpanded`) and stays out of `variantSnapshot`, so opening and closing a card does not count as an unsaved change.

The chips become Single and Pack; Custom goes, because it was a single card with a label and the variant-name field already covers that.

### Edit: one card, always open

The card never collapses and shows no ✕, as today.
The Single/Pack toggle replaces typing a pack size into a single item: opening a pack item selects Pack, from `packAmount > 1`.
`buildEditedItem` and `_splitEditableName` are unchanged, so an edited item keeps the `"<name> - <label> x<pack>"` shape.

## Risks and open questions

- **Blocking: Khmer wording.** The new labels — items per pack, the Single/Pack toggle, the ⚠ summary — need a native reading before they ship.
- **The cost-price label disagrees across languages, and English contradicts per-variant pricing.** English says "Default Price (per unit)"; Khmer "តម្លៃដើម" means cost price. A pack's prices are per pack, so "(per unit)" is wrong either way; the plan renames the English entry to "Cost price" to match the Khmer, pending your confirmation.
- **Dropping the Custom chip** removes a shortcut someone may use. The same result is Single plus a variant name.

## Testing

In `packages/jabhouy_shop/test/`:

| Case | Kind |
| --- | --- |
| `problems()` for empty customer price, pack under 2, clean draft | unit |
| Khmer digits and pasted `1,500` parse to 1500 | unit, on the formatter |
| A collapsed card with no price blocks save and expands | widget |
| Adding a card collapses the clean ones and leaves a broken one open | widget |
| Fixing a field clears its error without saving | widget |
| Edit shows one card, no chips, no ✕, no collapse | widget |
| Edit toggling Single → Pack → 24 saves `"<name> x24"` | widget |
| Opening and closing a card does not trip the unsaved-changes prompt | widget |

The layout at phone width is checked by running the app on the seller's phone.

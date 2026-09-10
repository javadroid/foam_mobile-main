# No-Folding Surcharge — Mobile Implementation Guide

## Why this changed

"No folding" used to be computed entirely on-device, independently, in both
web and mobile, using different triggers and never sent to the backend as
real data — only baked invisibly into a single `totalPrice` number. That
meant:

- The admin dashboard had no way to see which orders (or which items in an
  order) had a folding surcharge applied — `order.totalPrice` just didn't
  match the sum of the itemized rows, with no explanation.
- The eligibility rule (which categories the surcharge applies to) was a
  fragile string match (`category.description.includes("tops")`), and the
  rate (30%) was a hardcoded constant duplicated in two codebases.
- The client-supplied `totalPrice` was trusted verbatim by
  `POST /api/order/create` with no server-side verification — spoofable.

All of this has moved server-side. The backend is now the source of truth
for pricing, folding eligibility, and the folding decision itself. This doc
is the contract for bringing the Flutter app in line with it.

**Web's old UX (`Service.title` containing "no folding") has also changed**
to an explicit toggle on the basket screen — the same shape mobile's
existing `Switch` toggle already uses, so no UX change needed on your side,
just a backend contract change.

## What changed in the data model (context, not something you touch)

- `Category.foldingSurchargeRate: number | null` — a rate (e.g. `0.3` for
  30%) per category, replacing the old "description contains tops" check.
  Currently only the Tops-type categories have this set; everything else is
  `null` (no surcharge).
- `Item.foldingSurcharge: number` — a snapshot of the naira surcharge
  actually applied to that line, stored on order creation.
- `Order.noFolding: boolean` — whether the customer opted out of folding for
  that order.

## API changes you need to integrate

### 1. New: `POST /api/user/basket/quote`

Call this whenever the basket screen loads, and again every time the
folding toggle changes — it returns the authoritative, itemized price
breakdown for the caller's current basket. Replace
`calculateNoFoldingSurcharge()` in `basket_screen.dart` with a call to this
endpoint instead of computing it locally.

**Request:**
```
POST /api/user/basket/quote
Authorization: Bearer <token>
Content-Type: application/json

{ "noFolding": true }
```

**Response `200`:**
```json
{
  "items": [
    {
      "itemId": 281,
      "categoryId": 14,
      "name": "Jacket/Coat",
      "quantity": 2,
      "unitPrice": 1100,
      "foldingSurcharge": 660,
      "lineTotal": 2860
    },
    {
      "itemId": 282,
      "categoryId": 81,
      "name": "Baby Clothes",
      "quantity": 1,
      "unitPrice": 800,
      "foldingSurcharge": 0,
      "lineTotal": 800
    }
  ],
  "subtotal": 3000,
  "foldingSurchargeTotal": 660,
  "deliveryFee": 3000,
  "totalPrice": 6660
}
```

- `subtotal` — sum of `unitPrice * quantity` across all lines, before any
  surcharge or delivery fee.
- `foldingSurchargeTotal` — sum of every line's `foldingSurcharge`. Only
  non-zero for lines whose category has a `foldingSurchargeRate` **and**
  `noFolding: true` was sent.
- `deliveryFee` — currently a flat `3000` (naira) — no longer a client-side
  constant, read it from here.
- `totalPrice` — `subtotal + foldingSurchargeTotal + deliveryFee`. This is
  the number to display as the grand total, and the number that (converted
  to kobo) should be handed to Paystack.
- An empty basket returns the same shape with everything zeroed out, not an
  error.

### 2. `POST /api/order/create` — body shape changed

**Before:** the app presumably sent some form of `totalPrice`.
**Now:**
```json
{
  "noFolding": true,
  "paymentType": "ONLINE",
  "paymentId": "<paystack reference>",
  "paymentStatus": "SUCCEEDED"
}
```

`totalPrice` is **no longer accepted** — sending it does nothing, the server
computes it itself from the basket + `noFolding`, using the exact same
logic as the quote endpoint above. `noFolding` is now **required** — if
you're not sending it, the request will fail validation (`409`).

**Response `200`** now also includes `noFolding` and each item's
`foldingSurcharge` on the returned `order` object, if you want to show a
confirmation screen with the breakdown.

## Recommended flow

1. Basket screen loads → `POST /api/user/basket/quote` with
   `{ "noFolding": false }` (or whatever the toggle's current state is) →
   render the itemized breakdown + totals from the response.
2. User flips the "Skip folding?" switch → re-call the quote endpoint with
   the new value → re-render. Don't compute the surcharge locally anymore.
3. User proceeds to checkout/payment → call the quote endpoint **again**
   right before initializing Paystack (don't reuse a total from step 1/2 if
   any time has passed or the basket could have changed) → use
   `totalPrice * 100` as the kobo amount for Paystack.
4. On successful payment → `POST /api/order/create` with `noFolding` (the
   same value used for the last quote) + the payment reference. Don't send
   `totalPrice`.

## Two things to flag back, not to solve unilaterally

1. **No order-creation call was found anywhere in the current mobile
   codebase** (`grep -rn "order/create\|CreateOrder\|createOrder" lib`
   turned up nothing). If that's accurate, checkout may not currently
   complete against the backend at all on mobile — worth confirming this is
   a real gap (and not something that was just missed in a search) before
   assuming this guide's checkout flow already has a home to plug into.
2. **The surcharge rate is now per-category and admin-editable**, rather
   than a hardcoded `0.3`. Don't hardcode `30%` anywhere in the Flutter app
   going forward — always read `foldingSurcharge`/`foldingSurchargeRate`
   from the API, since an admin changing a category's rate should take
   effect on mobile without an app update.

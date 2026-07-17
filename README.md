# @raoltech/qris

Modular ESM QRIS (Quick Response Code Indonesian Standard) library for Node.js.
Converts static QRIS to dynamic QRIS with a full EMVCo TLV parser, transaction
store with expiry, webhook receiver, and multi-merchant registry.

## Features

- Full TLV parser (tags 00-64, nested templates 26-51 and 62)
- Static to dynamic conversion with amount and fee
- CRC16-CCITT validation (poly 0x1021)
- Transaction store with automatic expiry
- Webhook receiver with HMAC signature verification
- Multi-merchant registry (validates QRIS on add)
- Render QR to data URL or buffer (no heavy native dependencies)
- 100% ESM, zero native dependencies

## Install

Install directly from GitHub:

```bash
npm install raoltech/qris
```

Or with a pinned version / branch:

```bash
npm install github:raoltech/qris
npm install github:raoltech/qris#main
```

Then import:

```js
import {
  parseQRIS, makeString, toDataURL,
  TransactionStore, WebhookReceiver, MerchantRegistry,
} from "@raoltech/qris";
```

## Usage

```js
const STATIC = "000201010211...6304E0BD";

// Parse all TLV fields
const info = parseQRIS(STATIC);
console.log(info.merchantName, info.merchantCity, info.crcIsValid);

// Static to dynamic
const dyn = makeString(STATIC, { nominal: "50000" });

// Render to image
const { qrisString, qrImage } = await toDataURL(STATIC, { nominal: "50000" });
```

## Modules

### TLV Parser

`parseQRIS(qris)` returns a structured object:

| Field | Description |
|-------|-------------|
| `formatIndicator` | Payload format indicator (tag 00) |
| `initiationMode` | `static` or `dynamic` (tag 01) |
| `merchantName` | Merchant name (tag 59) |
| `merchantCity` | Merchant city (tag 60) |
| `country` | Country code (tag 58) |
| `currency` | Currency code (tag 53, `360` = IDR) |
| `amount` | Transaction amount (tag 54) |
| `merchantCategoryCode` | MCC (tag 52) |
| `merchantAccount` | Nested merchant account templates (26-51) |
| `additionalData` | Nested additional data fields (tag 62) |
| `crcIsValid` | CRC16 checksum verification result |

Lower-level helpers are also exported: `parseTLV(str)`,
`TAG_NAMES`, `ADDITIONAL_SUBTAG_NAMES`.

### Conversion

```js
// Embed amount
makeString(STATIC, { nominal: "50000" });

// With fee (r = fixed rupiah, p = percentage)
makeString(STATIC, { nominal: "50000", fee: "2500", taxtype: "r" });
makeString(STATIC, { nominal: "50000", fee: "2.5", taxtype: "p" });
```

### Field Setters

```js
import { setMerchantCity, setMerchantName, setField } from "@raoltech/qris";

setMerchantCity(STATIC, "Banjar");   // tag 60
setMerchantName(STATIC, "Toko");     // tag 59
setField(STATIC, "58", "ID");        // guarded field, requires { allowGuarded: true }
```

Tags `53` (currency) and `58` (country) are guarded because QRIS requires
`ID` + `360` for wallets to accept the code. Use `{ allowGuarded: true }` to
override.

### Transaction Store (expiry)

```js
import { TransactionStore } from "@raoltech/qris";

const store = new TransactionStore({ ttlMs: 15 * 60 * 1000 });

const tx = store.create({ qris: STATIC, nominal: 50000, customerName: "Budi" });
// tx.ref, tx.qrisString, tx.status = "pending", tx.expiresAt

store.confirm(tx.ref);     // status -> "paid"
store.get(tx.ref);         // auto "expired" once ttlMs has passed
store.list({ status: "pending" });
```

### Webhook Receiver (HMAC)

```js
import { WebhookReceiver } from "@raoltech/qris";

const wh = new WebhookReceiver({
  secret: "your-secret",
  onPayment: (ref) => console.log("paid:", ref),
});
```

In an Express handler:

```js
app.post("/api/webhook", (req, res) => {
  const raw = req.body; // raw JSON string
  if (!wh.verifySignature(raw, req.headers["x-signature"]))
    return res.status(401).end();
  res.json(wh.handle(JSON.parse(raw)));
});
```

Paid status is detected from: `paid`, `settlement`, `success`, `capture`,
`completed`. The reference is read from `ref`, `referenceId`, `reference_id`,
`id`, or `data.*`.

### Merchant Registry

```js
import { MerchantRegistry } from "@raoltech/qris";

const reg = new MerchantRegistry();
reg.add("dana1", { qris: STATIC, name: "Toko A" });
reg.add("dana2", { qris: OTHER_STATIC });   // throws if CRC invalid
reg.list();   // [{ id, name, merchantName, city, currency, crcValid }]
```

### Rendering

```js
import { toDataURL, toBuffer } from "@raoltech/qris";

const { qrisString, qrImage } = await toDataURL(STATIC, { nominal: "50000" });
const { qrisString, buffer } = await toBuffer(STATIC, { nominal: "50000" });
```

## API Reference

| Export | Description |
|--------|-------------|
| `parseQRIS(str)` | Full parse to structured object |
| `parseTLV(str)` | Low-level TLV parser |
| `makeString(str, opts)` | Static to dynamic QRIS string |
| `setAmount(str, nominal)` | Shortcut to set amount |
| `setField(str, tag, value, opts)` | Set arbitrary TLV tag |
| `setMerchantCity / setMerchantName` | Set tag 60 / 59 |
| `setCountry / setCurrency` | Set tag 58 / 53 (guarded) |
| `toDataURL(str, opts)` | Returns `{ qrisString, qrImage }` |
| `toBuffer(str, opts)` | Returns `{ qrisString, buffer }` |
| `TransactionStore` | In-memory transaction store with TTL |
| `WebhookReceiver` | HMAC-verified webhook handler |
| `MerchantRegistry` | Multi-merchant QRIS registry |
| `toCRC16(str)` / `pad2(n)` | CRC16 and length padding helpers |

## Project Structure

```
src/
  crc.js          CRC16 and padding
  tlv.js          Full EMVCo TLV parser
  convert.js      Static to dynamic conversion and field setters
  render.js       QR to data URL / buffer
  transaction.js  TransactionStore with expiry
  webhook.js      WebhookReceiver (HMAC)
  merchant.js     MerchantRegistry
  index.js        Public API
```


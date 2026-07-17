# @raoltech/qris

Modular **ESM** QRIS (Quick Response Code Indonesian Standard) library: static → dynamic conversion with full **EMVCo TLV parser**, transaction store with expiry, webhook receiver, and multi-merchant registry.

- ✅ Full TLV parser (tags 00–64 + nested 26–51 & 62)
- ✅ Static → dynamic conversion (amount + fee)
- ✅ CRC16-CCITT validation (poly 0x1021)
- ✅ Transaction store with auto-expiry
- ✅ Webhook receiver with HMAC signature verification
- ✅ Multi-merchant registry (validates QRIS on add)
- ✅ Render QR to data URL / buffer (no heavy deps)
- ✅ 100% ESM, zero native deps

## Install

```bash
npm i @raoltech/qris
```

## Usage

```js
import {
  parseQRIS, makeString, toDataURL,
  TransactionStore, WebhookReceiver, MerchantRegistry,
} from "@raoltech/qris";

const STATIC = "000201010211...6304E0BD";

// Parse all TLV fields
const info = parseQRIS(STATIC);
console.log(info.merchantName, info.merchantCity, info.crcIsValid);

// Static -> dynamic
const dyn = makeString(STATIC, { nominal: "50000" });

// Render to image
const { qrisString, qrImage } = await toDataURL(STATIC, { nominal: "50000" });
```

## Modules

### TransactionStore (expiry)

```js
const store = new TransactionStore({ ttlMs: 15 * 60 * 1000 });

const tx = store.create({ qris: STATIC, nominal: 50000, customerName: "Budi" });
// tx.ref, tx.qrisString, tx.status = "pending", tx.expiresAt

store.confirm(tx.ref);              // status -> "paid"
store.get(tx.ref);                  // auto "expired" if past ttlMs
```

### WebhookReceiver (HMAC verified)

```js
const wh = new WebhookReceiver({
  secret: "your-secret",
  onPayment: (ref) => console.log("paid:", ref),
});
// Express:
app.post("/api/webhook", (req, res) => {
  if (!wh.verifySignature(rawBody, req.headers["x-signature"]))
    return res.status(401).end();
  res.json(wh.handle(JSON.parse(rawBody)));
});
```

Detects paid status from: `paid`, `settlement`, `success`, `capture`, `completed`.
Ref extracted from: `ref`, `referenceId`, `reference_id`, `id`, or `data.*`.

### MerchantRegistry

```js
const reg = new MerchantRegistry();
reg.add("dana1", { qris: STATIC, name: "Toko A" });
reg.add("dana2", { qris: OTHER_STATIC });   // throws if CRC invalid
reg.list();   // [{ id, name, merchantName, city, ... }]
```

### Field setters (TLV)

```js
import { setMerchantCity, setMerchantName, setField } from "@raoltech/qris";
setMerchantCity(STATIC, "Banjar");   // tag 60
setMerchantName(STATIC, "Toko");     // tag 59
setField(STATIC, "58", "ID");        // guarded: needs { allowGuarded: true }
```

## API

| Function | Description |
|----------|-------------|
| `parseQRIS(str)` | Full parse → object (merchantName, city, amount, merchantAccount, additionalData, crcIsValid, …) |
| `makeString(str, {nominal, taxtype, fee})` | Static → dynamic QRIS string |
| `toDataURL(str, opts)` | → `{ qrisString, qrImage }` (base64 PNG) |
| `toBuffer(str, opts)` | → `{ qrisString, buffer }` (PNG buffer) |
| `TransactionStore` | In-memory tx store with TTL expiry |
| `WebhookReceiver` | HMAC-verified webhook handler |
| `MerchantRegistry` | Multi-merchant QRIS registry |
| `toCRC16(str)` | CRC16-CCITT |

## Structure

```
src/
├── crc.js          # CRC16 + padding
├── tlv.js          # Full EMVCo TLV parser
├── convert.js      # Static -> Dynamic + field setters
├── render.js       # QR -> dataURL/buffer
├── transaction.js  # TransactionStore + expiry
├── webhook.js      # WebhookReceiver (HMAC)
├── merchant.js     # MerchantRegistry
└── index.js        # Public API
```

## License

MIT © raoltech

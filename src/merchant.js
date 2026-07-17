import { parseQRIS } from "./tlv.js";

export class MerchantRegistry {
  constructor() {
    this.merchants = new Map();
  }

  add(id, { qris, name }) {
    const parsed = parseQRIS(qris);
    if (!parsed.crcIsValid) throw new Error("QRIS tidak valid (CRC mismatch)");
    const m = {
      id,
      name: name || parsed.merchantName,
      qris,
      merchantName: parsed.merchantName,
      city: parsed.merchantCity,
      currency: parsed.currency,
      crcValid: parsed.crcIsValid,
    };
    this.merchants.set(id, m);
    return m;
  }

  get(id) {
    return this.merchants.get(id) || null;
  }

  list() {
    return [...this.merchants.values()].map(({ qris, ...rest }) => rest);
  }
}

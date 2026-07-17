import crypto from "node:crypto";
import { makeString, setMerchantCity, setMerchantName } from "./convert.js";
import QRCode from "qrcode";
import { parseQRIS } from "./tlv.js";

const DEFAULT_TTL_MS = 15 * 60 * 1000;

export class TransactionStore {
  constructor({ ttlMs = DEFAULT_TTL_MS } = {}) {
    this.ttlMs = ttlMs;
    this.map = new Map();
  }

  create({ qris, nominal, customerName, description, fee = "0", taxtype = "p", city, name, refPrefix = "RAOL" }) {
    const ref = refPrefix + Date.now().toString(36).toUpperCase() + crypto.randomBytes(2).toString("hex").toUpperCase();
    let base = qris;
    if (city) base = setMerchantCity(base, city);
    if (name) base = setMerchantName(base, name);

    const qrisString = makeString(base, { nominal: String(nominal), fee: String(fee), taxtype });
    const expiresAt = Date.now() + this.ttlMs;

    const tx = {
      ref,
      nominal: Number(nominal),
      customerName: customerName || null,
      description: description || null,
      fee: Number(fee),
      taxtype,
      qrisString,
      status: "pending",
      createdAt: new Date().toISOString(),
      expiresAt: new Date(expiresAt).toISOString(),
      paidAt: null,
    };
    this.map.set(ref, tx);
    return tx;
  }

  get(ref) {
    const tx = this.map.get(ref);
    if (!tx) return null;
    if (tx.status === "pending" && Date.now() > new Date(tx.expiresAt).getTime()) {
      tx.status = "expired";
    }
    return tx;
  }

  confirm(ref, { method = "manual" } = {}) {
    const tx = this.map.get(ref);
    if (!tx) return null;
    if (tx.status === "expired") throw new Error("transaksi sudah expired");
    tx.status = "paid";
    tx.paidAt = new Date().toISOString();
    tx.paidMethod = method;
    return tx;
  }

  list({ status } = {}) {
    const all = [...this.map.values()];
    return status ? all.filter((t) => t.status === status) : all;
  }

  purgeExpired() {
    const now = Date.now();
    for (const [ref, tx] of this.map) {
      if (tx.status === "pending" && now > new Date(tx.expiresAt).getTime()) {
        tx.status = "expired";
      }
    }
  }
}

export async function receiptQR(tx) {
  const qrImage = await QRCode.toDataURL(tx.qrisString, { margin: 2, width: 420, errorCorrectionLevel: "M" });
  return { ...tx, qrImage, parsed: parseQRIS(tx.qrisString) };
}

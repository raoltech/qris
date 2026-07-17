import { test } from "node:test";
import assert from "node:assert/strict";
import crypto from "node:crypto";
import { TransactionStore, receiptQR } from "../src/transaction.js";
import { WebhookReceiver } from "../src/webhook.js";
import { MerchantRegistry } from "../src/merchant.js";
import { parseQRIS } from "../src/index.js";

const STATIC = "00020101021126570011ID.DANA.WWW011893600915303023251702090302325170303UMI51440014ID.CO.QRIS.WWW0215ID10265294489570303UMI5204737253033605802ID5914Raol Mukarrozi6015Kota Banjar Bar6105707316304E0BD";

test("TransactionStore.create generates ref + dynamic qris", () => {
  const store = new TransactionStore({ ttlMs: 1000 });
  const tx = store.create({ qris: STATIC, nominal: 50000, description: "Test" });
  assert.match(tx.ref, /^RAOL/);
  assert.equal(parseQRIS(tx.qrisString).amount, "50000");
  assert.equal(tx.status, "pending");
});

test("TransactionStore auto-expires", async () => {
  const store = new TransactionStore({ ttlMs: 50 });
  const tx = store.create({ qris: STATIC, nominal: 1000 });
  await new Promise((r) => setTimeout(r, 80));
  const got = store.get(tx.ref);
  assert.equal(got.status, "expired");
});

test("TransactionStore.confirm sets paid", () => {
  const store = new TransactionStore();
  const tx = store.create({ qris: STATIC, nominal: 2000 });
  const c = store.confirm(tx.ref);
  assert.equal(c.status, "paid");
  assert.ok(c.paidAt);
});

test("receiptQR returns dataURL", async () => {
  const store = new TransactionStore();
  const tx = store.create({ qris: STATIC, nominal: 3000 });
  const r = await receiptQR(tx);
  assert.ok(r.qrImage.startsWith("data:image/png;base64,"));
});

test("WebhookReceiver.verifySignature HMAC", () => {
  const wh = new WebhookReceiver({ secret: "abc" });
  const body = JSON.stringify({ ref: "RAOL1", status: "paid" });
  const sig = crypto.createHmac("sha256", "abc").update(body, "utf8").digest("hex");
  assert.equal(wh.verifySignature(body, sig), true);
  assert.equal(wh.verifySignature(body, "wrong"), false);
});

test("WebhookReceiver.handle confirms on paid status", () => {
  const events = [];
  const wh = new WebhookReceiver({ onPayment: (ref) => events.push(ref) });
  const res = wh.handle({ ref: "RAOLX", status: "settlement" });
  assert.equal(res.action, "confirmed");
  assert.deepEqual(events, ["RAOLX"]);
});

test("MerchantRegistry rejects invalid QRIS", () => {
  const reg = new MerchantRegistry();
  reg.add("dana1", { qris: STATIC, name: "Store" });
  assert.equal(reg.get("dana1").merchantName, "Raol Mukarrozi");
  assert.throws(() => reg.add("bad", { qris: STATIC.slice(0, -4) + "0000" }));
});

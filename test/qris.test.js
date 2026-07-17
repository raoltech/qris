import { test } from "node:test";
import assert from "node:assert/strict";
import { parseQRIS, makeString, toDataURL, toCRC16, setMerchantCity, setMerchantName } from "../src/index.js";

const STATIC =
  "00020101021126570011ID.DANA.WWW011893600915303023251702090302325170303UMI51440014ID.CO.QRIS.WWW0215ID10265294489570303UMI5204737253033605802ID5914Raol Mukarrozi6015Kota Banjar Bar6105707316304E0BD";

test("parse static QRIS extracts full TLV fields", () => {
  const d = parseQRIS(STATIC);
  assert.equal(d.initiationMode, "static");
  assert.equal(d.merchantName, "Raol Mukarrozi");
  assert.equal(d.merchantCity, "Kota Banjar Bar");
  assert.equal(d.country, "ID");
  assert.equal(d.currency, "360");
  assert.ok(d.crcIsValid, "CRC must be valid");
  assert.ok(d.merchantAccount.length > 0, "should contain merchant account info");
});

test("makeString converts to dynamic with embedded amount", () => {
  const dyn = makeString(STATIC, { nominal: "50000" });
  const d = parseQRIS(dyn);
  assert.equal(d.initiationMode, "dynamic");
  assert.equal(d.amount, "50000");
  assert.ok(d.crcIsValid, "dynamic CRC must be valid");
});

test("toDataURL returns image + string", async () => {
  const { qrisString, qrImage } = await toDataURL(STATIC, { nominal: "25000" });
  assert.ok(qrisString.startsWith("000201010212"));
  assert.ok(qrImage.startsWith("data:image/png;base64,"));
});

test("CRC16 of known payload matches embedded CRC", () => {
  const input = STATIC.slice(0, -4);
  assert.equal(toCRC16(input), STATIC.slice(-4));
});

test("setMerchantCity changes TLV 60 and keeps CRC valid", () => {
  const out = setMerchantCity(STATIC, "Banjar");
  const d = parseQRIS(out);
  assert.equal(d.merchantCity, "Banjar");
  assert.ok(d.crcIsValid);
});

test("setMerchantName changes TLV 59 and keeps CRC valid", () => {
  const out = setMerchantName(STATIC, "Toko Raol");
  const d = parseQRIS(out);
  assert.equal(d.merchantName, "Toko Raol");
  assert.ok(d.crcIsValid);
});

import { toCRC16, pad2 } from "./crc.js";
import { parseTLV } from "./tlv.js";

export function makeString(qris, { nominal, taxtype = "p", fee = "0" } = {}) {
  if (!qris) throw new Error('Parameter "qris" wajib diisi.');
  if (!nominal) throw new Error('Parameter "nominal" wajib diisi.');

  let tax = "";
  let qrisModified = qris.slice(0, -4).replace("010211", "010212");
  let parts = qrisModified.split("5802ID");

  let amount = "54" + pad2(String(nominal).length) + nominal;

  if (taxtype && fee) {
    tax =
      taxtype === "p"
        ? "55020357" + pad2(String(fee).length) + fee
        : "55020256" + pad2(String(fee).length) + fee;
  }

  amount += tax.length === 0 ? "5802ID" : tax + "5802ID";
  let output = parts[0].trim() + amount + parts[1].trim();
  output += toCRC16(output);
  return output;
}

export function setAmount(qris, nominal) {
  return makeString(qris, { nominal });
}

const GUARDED_TAGS = new Set(["53", "58"]);

function encodeTLV(tag, value) {
  return tag + pad2(String(value).length) + value;
}

export function setField(qris, tag, value, { allowGuarded = false } = {}) {
  if (!qris) throw new Error('Parameter "qris" wajib diisi.');
  if (!/^\d{2}$/.test(tag)) throw new Error("Tag harus 2 digit (contoh: 59, 60, 58, 53).");
  if (GUARDED_TAGS.has(tag) && !allowGuarded) {
    throw new Error(
      `Tag ${tag} adalah field sistem (currency/country). Pakai { allowGuarded: true } jika yakin ingin mengubahnya.`
    );
  }

  const body = qris.slice(0, -4);
  const elements = parseTLV(body);
  const target = elements.find((e) => e.tag === tag);

  let out;
  if (target) {
    const oldBlock = tag + pad2(target.length) + target.value;
    out = body.replace(oldBlock, encodeTLV(tag, value));
  } else {
    out = body + encodeTLV(tag, value);
  }

  out += toCRC16(out);
  return out;
}

export function setMerchantCity(qris, city) {
  return setField(qris, "60", city);
}

export function setMerchantName(qris, name) {
  return setField(qris, "59", name);
}

export function setCountry(qris, country, opts) {
  return setField(qris, "58", country, opts);
}

export function setCurrency(qris, currency, opts) {
  return setField(qris, "53", currency, opts);
}

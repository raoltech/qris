import { parseQRIS } from "./tlv.js";

export function validateQRIS(qris) {
  if (typeof qris !== "string" || qris.length < 20) {
    return { valid: false, error: "QRIS terlalu pendek atau bukan string" };
  }
  const parsed = parseQRIS(qris);
  if (!parsed.crcIsValid) {
    return { valid: false, error: "CRC tidak valid", expected: parsed.crcComputed, got: parsed.crc };
  }
  if (!parsed.merchantName) {
    return { valid: false, error: "Nama merchant (tag 59) tidak ditemukan" };
  }
  if (parsed.currency !== "360") {
    return { valid: false, error: "Currency bukan IDR (360)" };
  }
  return { valid: true, parsed };
}

export function prettyPrint(qris) {
  const p = parseQRIS(qris);
  const rows = [];
  const push = (k, v) => { if (v) rows.push(`${k.padEnd(18)}: ${v}`); };
  push("Format", p.formatIndicator);
  push("Initiation", `${p.initiationMethod} (${p.initiationMode})`);
  push("Merchant", p.merchantName);
  push("City", p.merchantCity);
  push("Category", p.merchantCategoryCode);
  push("Currency", p.currency);
  push("Amount", p.amount || "-");
  push("Country", p.country);
  push("CRC", `${p.crc} (${p.crcIsValid ? "valid" : "INVALID " + p.crcComputed})`);
  if (p.additionalData && Object.keys(p.additionalData).length) {
    for (const [k, v] of Object.entries(p.additionalData)) {
      rows.push(`${v.name.padEnd(18)}: ${v.value}`);
    }
  }
  return rows.join("\n");
}

import { toCRC16 } from "./crc.js";

const TAG_NAMES = {
  "00": "Payload Format Indicator",
  "01": "Point of Initiation Method",
  "26": "Merchant Account Information (Template)",
  "27": "Merchant Account Information (Template)",
  "28": "Merchant Account Information (Template)",
  "29": "Merchant Account Information (Template)",
  "30": "Merchant Account Information (Template)",
  "31": "Merchant Account Information (Template)",
  "32": "Merchant Account Information (Template)",
  "33": "Merchant Account Information (Template)",
  "34": "Merchant Account Information (Template)",
  "35": "Merchant Account Information (Template)",
  "36": "Merchant Account Information (Template)",
  "37": "Merchant Account Information (Template)",
  "38": "Merchant Account Information (Template)",
  "39": "Merchant Account Information (Template)",
  "40": "Merchant Account Information (Template)",
  "41": "Merchant Account Information (Template)",
  "42": "Merchant Account Information (Template)",
  "43": "Merchant Account Information (Template)",
  "44": "Merchant Account Information (Template)",
  "45": "Merchant Account Information (Template)",
  "46": "Merchant Account Information (Template)",
  "47": "Merchant Account Information (Template)",
  "48": "Merchant Account Information (Template)",
  "49": "Merchant Account Information (Template)",
  "50": "Merchant Account Information (Template)",
  "51": "Merchant Account Information (Template)",
  "52": "Merchant Category Code",
  "53": "Transaction Currency",
  "54": "Transaction Amount",
  "55": "Tip or Convenience Indicator",
  "56": "Value of Convenience Fee (Fixed)",
  "57": "Value of Convenience Fee (Percentage)",
  "58": "Country Code",
  "59": "Merchant Name",
  "60": "Merchant City",
  "61": "Postal Code",
  "62": "Additional Data Field Template",
  "63": "CRC",
  "64": "Merchant Information Language Template",
};

const ADDITIONAL_SUBTAG_NAMES = {
  "01": "Bill Number",
  "02": "Mobile Number",
  "03": "Store Label",
  "04": "Loyalty Number",
  "05": "Reference Label",
  "06": "Customer Label",
  "07": "Terminal Label",
  "08": "Purpose of Transaction",
  "09": "Additional Consumer Data Request",
};

function parseTLV(str) {
  const out = [];
  let i = 0;
  while (i < str.length) {
    const tag = str.slice(i, i + 2);
    if (tag.length < 2) break;
    const len = parseInt(str.slice(i + 2, i + 4), 10);
    if (Number.isNaN(len)) break;
    const value = str.slice(i + 4, i + 4 + len);
    out.push({ tag, name: TAG_NAMES[tag] || "Unknown", length: len, value });
    i += 4 + len;
  }
  return out;
}

function parseNested(templateValue) {
  return parseTLV(templateValue);
}

export function parseQRIS(qris) {
  const raw = parseTLV(qris);
  const map = Object.fromEntries(raw.map((e) => [e.tag, e.value]));

  const merchantAccount = raw
    .filter((e) => e.tag >= "26" && e.tag <= "51")
    .map((e) => ({ tag: e.tag, fields: parseNested(e.value) }));

  const additional = map["62"]
    ? parseNested(map["62"]).reduce((acc, f) => {
        acc[f.tag] = { name: ADDITIONAL_SUBTAG_NAMES[f.tag] || "Unknown", value: f.value };
        return acc;
      }, {})
    : {};

  const crcInput = qris.slice(0, -4);
  const crcFromQris = qris.slice(-4);
  const crcComputed = toCRC16(crcInput);

  return {
    formatIndicator: map["00"] || null,
    initiationMethod: map["01"] || null,
    initiationMode: map["01"] === "11" ? "static" : map["01"] === "12" ? "dynamic" : "unknown",
    merchantCategoryCode: map["52"] || null,
    currency: map["53"] || null,
    amount: map["54"] || null,
    tipIndicator: map["55"] || null,
    feeFixed: map["56"] || null,
    feePercent: map["57"] || null,
    country: map["58"] || null,
    merchantName: map["59"] || null,
    merchantCity: map["60"] || null,
    postalCode: map["61"] || null,
    additionalData: additional,
    merchantAccount,
    crc: crcFromQris,
    crcComputed,
    raw,
    crcIsValid: crcFromQris === crcComputed,
  };
}

export { parseTLV, TAG_NAMES, ADDITIONAL_SUBTAG_NAMES };

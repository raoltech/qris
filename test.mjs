import * as Q from "./src/index.js";
import QRCode from "qrcode";
import { Jimp } from "jimp";
import jsQR from "jsqr";
import fs from "node:fs";
import path from "node:path";

const DANA = "00020101021126570011ID.DANA.WWW011893600915303023251702090302325170303UMI51440014ID.CO.QRIS.WWW0215ID10265294489570303UMI5204737253033605802ID5914Raol Mukarrozi6015Kota Banjar Bar6105707316304E0BD";

const OUT = path.resolve("output");
fs.mkdirSync(OUT, { recursive: true });

const results = [];
const A = (name, cond, extra = "") => results.push({ name, pass: !!cond, extra });

function write(file, data) {
  fs.writeFileSync(path.join(OUT, file), data);
}

async function main() {
  const report = [];
  report.push("=== QRIS MODULAR FULL TEST (Dana ID) ===");
  report.push("Dana QRIS: " + DANA);
  report.push("");

  const p = Q.parseQRIS(DANA);
  A("parse merchant name", p.merchantName === "Raol Mukarrozi", p.merchantName);
  A("parse merchant city", p.merchantCity === "Kota Banjar Bar", p.merchantCity);
  A("parse currency 360", p.currency === "360", p.currency);
  A("parse static mode", p.initiationMode === "static", p.initiationMode);
  A("parse CRC valid", p.crcIsValid === true, p.crc);

  const renamed = Q.setMerchantName(DANA, "TOKO NEOBRUTAL");
  A("setMerchantName (TLV 59)", Q.parseQRIS(renamed).merchantName === "TOKO NEOBRUTAL");
  A("rename keeps CRC valid", Q.parseQRIS(renamed).crcIsValid === true);

  const recity = Q.setMerchantCity(DANA, "BANDUNG");
  A("setMerchantCity (TLV 60)", Q.parseQRIS(recity).merchantCity === "BANDUNG");

  const setF = Q.setField(DANA, "59", "WARUNG ABC");
  A("setField tag 59", Q.parseQRIS(setF).merchantName === "WARUNG ABC");

  const dyn = Q.makeString(DANA, { nominal: "50000" });
  const pd = Q.parseQRIS(dyn);
  A("makeString amount 50000", pd.amount === "50000", pd.amount);
  A("makeString dynamic mode", pd.initiationMode === "dynamic", pd.initiationMode);
  A("makeString CRC valid", pd.crcIsValid === true);

  const dynFee = Q.makeString(DANA, { nominal: "75000", fee: "2.5", taxtype: "p" });
  A("makeString with fee", Q.parseQRIS(dynFee).amount === "75000");

  const dynRenamed = Q.makeString(renamed, { nominal: "100000" });
  A("dynamic + renamed amount", Q.parseQRIS(dynRenamed).amount === "100000");
  A("dynamic + renamed name", Q.parseQRIS(dynRenamed).merchantName === "TOKO NEOBRUTAL");

  const reg = new Q.MerchantRegistry();
  reg.add("DANA1", { qris: DANA, name: "Dana Raol" });
  A("MerchantRegistry add/get", reg.get("DANA1")?.merchantName === "Raol Mukarrozi");
  A("MerchantRegistry list", reg.list().length === 1);

  const store = new Q.TransactionStore();
  const tx = store.create({ qris: DANA, nominal: "120000", customerName: "Budi", description: "Test" });
  A("TransactionStore create", tx.status === "pending" && tx.ref.startsWith("RAOL"), tx.ref);
  A("Transaction qrisString dynamic", Q.parseQRIS(tx.qrisString).amount === "120000");
  store.confirm(tx.ref);
  A("TransactionStore confirm", store.get(tx.ref).status === "paid");
  A("TransactionStore list", store.list().length >= 1);

  const wh = new Q.WebhookReceiver({
    onPayment: (ref) => { const t = store.get(ref); if (t) { t.status = "paid"; t.paidMethod = "webhook"; } },
  });
  const tx2 = store.create({ qris: DANA, nominal: "5000" });
  const whRes = wh.handle({ ref: tx2.ref, status: "paid" });
  A("WebhookReceiver confirm", store.get(tx2.ref).status === "paid" && whRes.action === "confirmed");

  const v = Q.validateQRIS(DANA);
  A("validateQRIS valid", v.valid === true);
  const bad = Q.validateQRIS(DANA.slice(0, -4) + "0000");
  A("validateQRIS detects bad CRC", bad.valid === false);

  const pp = Q.prettyPrint(DANA);
  A("prettyPrint contains merchant", pp.includes("Raol Mukarrozi"));

  const durl = await Q.toDataURL(dyn);
  A("toDataURL returns image", typeof durl.qrImage === "string" && durl.qrImage.startsWith("data:image"));

  const buf = await Q.toBuffer(dyn);
  write("qris-dynamic-50000.png", buf.buffer);
  A("toBuffer png written", fs.statSync(path.join(OUT, "qris-dynamic-50000.png")).size > 0);

  const jpg = await Q.toJPG(dynRenamed, { nominal: "100000", width: 480 });
  write("qris-dynamic-100000.jpg", jpg.buffer);
  A("toJPG written (JPG output)", fs.statSync(path.join(OUT, "qris-dynamic-100000.jpg")).size > 0 && jpg.mime === "image/jpeg");

  const imgFile = path.join(OUT, "qris-decode-test.png");
  const dbuf = await QRCode.toBuffer(dyn, { margin: 2, width: 420, type: "png" });
  fs.writeFileSync(imgFile, dbuf);
  const img = await Jimp.read(imgFile);
  const decoded = jsQR(new Uint8ClampedArray(img.bitmap.data), img.bitmap.width, img.bitmap.height);
  A("decodeFromFile/AndParse (round-trip)", decoded && Q.parseQRIS(decoded.data).amount === "50000", decoded ? decoded.data.slice(0, 20) : "none");

  write("qris-string-100000.txt", dynRenamed);
  write("report-pretty.txt", pp);

  report.push("--- TEST RESULTS ---");
  let pass = 0;
  for (const r of results) {
    report.push(`${r.pass ? "PASS" : "FAIL"} - ${r.name}${r.extra ? " [" + r.extra + "]" : ""}`);
    if (r.pass) pass++;
  }
  report.push("");
  report.push(`TOTAL: ${pass}/${results.length} PASS`);
  report.push("");
  report.push("--- PRETTY PRINT (Dana) ---");
  report.push(pp);
  report.push("");
  report.push("--- OUTPUT FILES ---");
  report.push("qris-dynamic-50000.png");
  report.push("qris-dynamic-100000.jpg");
  report.push("qris-decode-test.png");
  report.push("qris-string-100000.txt");
  report.push("report-pretty.txt");

  write("REPORT.txt", report.join("\n"));

  console.log(report.join("\n"));

  const failed = results.filter((r) => !r.pass);
  if (failed.length) {
    console.error(`\n${failed.length} test(s) FAILED`);
    process.exit(1);
  }
  console.log(`\nALL ${results.length} TESTS PASSED`);
}

main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});

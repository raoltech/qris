import QRCode from "qrcode";
import { makeString } from "./convert.js";

export async function toDataURL(qris, opts = {}) {
  const str = makeString(qris, opts);
  const dataUrl = await QRCode.toDataURL(str, {
    margin: 2,
    width: 420,
    errorCorrectionLevel: "M",
    ...opts.qrOptions,
  });
  return { qrisString: str, qrImage: dataUrl };
}

export async function toBuffer(qris, opts = {}) {
  const str = makeString(qris, opts);
  const buffer = await QRCode.toBuffer(str, {
    margin: 2,
    width: 420,
    type: "png",
    ...opts.qrOptions,
  });
  return { qrisString: str, buffer };
}

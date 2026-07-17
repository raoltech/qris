import jsQR from "jsqr";

export async function decodeFromFile(pathOrBuffer) {
  const { Jimp } = await import("jimp");
  const image = await Jimp.read(pathOrBuffer);
  const { data, width, height } = image.bitmap;
  const clamped = new Uint8ClampedArray(data);
  const result = jsQR(clamped, width, height);
  if (!result || !result.data) throw new Error("no QR code found in image");
  return result.data;
}

export async function decodeAndParse(pathOrBuffer, { parse = true } = {}) {
  const { parseQRIS } = await import("./tlv.js");
  const raw = await decodeFromFile(pathOrBuffer);
  return parse ? parseQRIS(raw) : raw;
}

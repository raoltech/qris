export function toCRC16(input) {
  let crc = 0xffff;
  for (let i = 0; i < input.length; i++) {
    crc ^= input.charCodeAt(i) << 8;
    for (let j = 0; j < 8; j++) {
      crc = crc & 0x8000 ? (crc << 1) ^ 0x1021 : crc << 1;
    }
  }
  const hex = (crc & 0xffff).toString(16).toUpperCase();
  return hex.length === 3 ? "0" + hex : hex;
}

export function pad2(n) {
  return n < 10 ? "0" + n : String(n);
}

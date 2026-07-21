String toCRC16(String input) {
  int crc = 0xffff;
  for (int i = 0; i < input.length; i++) {
    crc ^= input.codeUnitAt(i) << 8;
    for (int j = 0; j < 8; j++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) : (crc << 1);
    }
  }
  final hex = (crc & 0xffff).toRadixString(16).toUpperCase();
  return hex.padLeft(4, '0');
}

String pad2(String n) => n.length < 2 ? '0' + n : n;

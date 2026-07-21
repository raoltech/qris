import 'tlv.dart';

class ValidationResult {
  ValidationResult({required this.valid, this.error, this.parsed});
  final bool valid;
  final String? error;
  final ParsedQRIS? parsed;
}

ValidationResult validateQRIS(String qris) {
  if (qris.length < 20) {
    return ValidationResult(valid: false, error: "QRIS terlalu pendek atau bukan string");
  }
  final parsed = parseQRIS(qris);
  if (!parsed.crcIsValid!) {
    return ValidationResult(valid: false, error: "CRC tidak valid", parsed: parsed);
  }
  if (parsed.merchantName == null || parsed.merchantName!.isEmpty) {
    return ValidationResult(valid: false, error: "Nama merchant (tag 59) tidak ditemukan", parsed: parsed);
  }
  if (parsed.currency != "360") {
    return ValidationResult(valid: false, error: "Currency bukan IDR (360)", parsed: parsed);
  }
  return ValidationResult(valid: true, parsed: parsed);
}

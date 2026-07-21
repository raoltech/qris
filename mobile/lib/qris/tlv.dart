import 'crc.dart';

const Map<String, String> tagNames = {
  "00": "Payload Format Indicator",
  "01": "Point of Initiation Method",
  "26": "Merchant Account Information",
  "27": "Merchant Account Information",
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

const Map<String, String> additionalSubtagNames = {
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

class TlvEntry {
  final String tag;
  final String name;
  final int length;
  final String value;
  TlvEntry(this.tag, this.name, this.length, this.value);
}

List<TlvEntry> parseTLV(String str) {
  final out = <TlvEntry>[];
  int i = 0;
  while (i < str.length) {
    if (i + 4 > str.length) break;
    final tag = str.substring(i, i + 2);
    final len = int.tryParse(str.substring(i + 2, i + 4)) ?? -1;
    if (len < 0) break;
    final end = i + 4 + len;
    if (end > str.length) break;
    final value = str.substring(i + 4, end);
    out.add(TlvEntry(tag, tagNames[tag] ?? "Unknown", len, value));
    i = end;
  }
  return out;
}

class ParsedQRIS {
  ParsedQRIS({
    this.formatIndicator,
    this.initiationMethod,
    this.initiationMode,
    this.merchantCategoryCode,
    this.currency,
    this.amount,
    this.country,
    this.merchantName,
    this.merchantCity,
    this.postalCode,
    this.additionalData,
    this.merchantAccount,
    this.crc,
    this.crcComputed,
    this.crcIsValid,
    this.raw,
  });

  final String? formatIndicator;
  final String? initiationMethod;
  final String? initiationMode;
  final String? merchantCategoryCode;
  final String? currency;
  final String? amount;
  final String? country;
  final String? merchantName;
  final String? merchantCity;
  final String? postalCode;
  final Map<String, dynamic>? additionalData;
  final List<dynamic>? merchantAccount;
  final String? crc;
  final String? crcComputed;
  final bool? crcIsValid;
  final List<TlvEntry>? raw;

  String pretty() {
    final rows = <String>[];
    void push(String k, String? v) {
      if (v != null && v.isNotEmpty) rows.add('${k.padRight(18)}: $v');
    }

    push("Format", formatIndicator);
    push("Initiation", "$initiationMethod (${initiationMode ?? '-'})");
    push("Merchant", merchantName);
    push("City", merchantCity);
    push("Category", merchantCategoryCode);
    push("Currency", currency);
    push("Amount", amount ?? "-");
    push("Country", country);
    push("CRC", "$crc (${crcIsValid == true ? 'valid' : 'INVALID ${crcComputed ?? ''}'})");
    if (additionalData != null) {
      for (final e in additionalData!.entries) {
        final v = e.value as Map<String, dynamic>;
        rows.add('${(v['name'] as String).padRight(18)}: ${v['value']}');
      }
    }
    return rows.join("\n");
  }
}

ParsedQRIS parseQRIS(String qris) {
  final raw = parseTLV(qris);
  final map = {for (final e in raw) e.tag: e.value};
  final merchantAccount = raw
      .where((e) => e.tag.compareTo("26") >= 0 && e.tag.compareTo("51") <= 0)
      .map((e) => {"tag": e.tag, "fields": parseTLV(e.value)})
      .toList();
  Map<String, dynamic> additional = {};
  if (map["62"] != null) {
    for (final f in parseTLV(map["62"]!)) {
      additional[f.tag] = {
        "name": additionalSubtagNames[f.tag] ?? "Unknown",
        "value": f.value,
      };
    }
  }
  final crcInput = qris.substring(0, qris.length - 4);
  final crcFrom = qris.substring(qris.length - 4);
  final crcComputed = toCRC16(crcInput);
  String mode = "unknown";
  if (map["01"] == "11") mode = "static";
  if (map["01"] == "12") mode = "dynamic";
  return ParsedQRIS(
    formatIndicator: map["00"],
    initiationMethod: map["01"],
    initiationMode: mode,
    merchantCategoryCode: map["52"],
    currency: map["53"],
    amount: map["54"],
    country: map["58"],
    merchantName: map["59"],
    merchantCity: map["60"],
    postalCode: map["61"],
    additionalData: additional,
    merchantAccount: merchantAccount,
    crc: crcFrom,
    crcComputed: crcComputed,
    crcIsValid: crcFrom == crcComputed,
    raw: raw,
  );
}

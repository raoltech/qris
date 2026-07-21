import 'crc.dart';

const Map<String, String> tagNames = {
  "00": "Payload Format Indicator",
  "01": "Point of Initiation Method",
  "02": "Reserved (Automated Teller Machine)",
  "03": "Reserved (Automated Teller Machine)",
  "04": "Reserved (Automated Teller Machine)",
  "05": "Reserved (Automated Teller Machine)",
  "06": "Reserved (Automated Teller Machine)",
  "07": "Reserved (Automated Teller Machine)",
  "08": "Reserved (Automated Teller Machine)",
  "09": "Reserved (Automated Teller Machine)",
  "10": "Reserved (Automated Teller Machine)",
  "11": "Reserved (Automated Teller Machine)",
  "12": "Reserved (Automated Teller Machine)",
  "13": "Reserved (Automated Teller Machine)",
  "14": "Reserved (Automated Teller Machine)",
  "15": "Reserved (Automated Teller Machine)",
  "16": "Reserved (Automated Teller Machine)",
  "17": "Reserved (Automated Teller Machine)",
  "18": "Reserved (Automated Teller Machine)",
  "19": "Reserved (Automated Teller Machine)",
  "20": "Reserved (Automated Teller Machine)",
  "21": "Reserved (Automated Teller Machine)",
  "22": "Reserved (Automated Teller Machine)",
  "23": "Reserved (Automated Teller Machine)",
  "24": "Reserved (Automated Teller Machine)",
  "25": "Reserved (Automated Teller Machine)",
  "26": "Merchant Account Info (Template)",
  "27": "Merchant Account Info (Template)",
  "28": "Merchant Account Info (Template)",
  "29": "Merchant Account Info (Template)",
  "30": "Merchant Account Info (Template)",
  "31": "Merchant Account Info (Template)",
  "32": "Merchant Account Info (Template)",
  "33": "Merchant Account Info (Template)",
  "34": "Merchant Account Info (Template)",
  "35": "Merchant Account Info (Template)",
  "36": "Merchant Account Info (Template)",
  "37": "Merchant Account Info (Template)",
  "38": "Merchant Account Info (Template)",
  "39": "Merchant Account Info (Template)",
  "40": "Merchant Account Info (Template)",
  "41": "Merchant Account Info (Template)",
  "42": "Merchant Account Info (Template)",
  "43": "Merchant Account Info (Template)",
  "44": "Merchant Account Info (Template)",
  "45": "Merchant Account Info (Template)",
  "46": "Merchant Account Info (Template)",
  "47": "Merchant Account Info (Template)",
  "48": "Merchant Account Info (Template)",
  "49": "Merchant Account Info (Template)",
  "50": "Merchant Account Info (Template)",
  "51": "Merchant Account Info (Template)",
  "52": "Merchant Category Code (MCC)",
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
  "64": "Merchant Info Language Template",
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

const Map<String, String> merchantSubtagNames = {
  "00": "Globally Unique Identifier (GUI)",
  "01": "Payment Network Specific",
  "02": "Payment Network Specific",
  "03": "Payment Network Specific",
  "04": "Payment Network Specific",
  "05": "Payment Network Specific",
  "06": "Payment Network Specific",
  "07": "Payment Network Specific",
  "08": "Payment Network Specific",
  "09": "Payment Network Specific",
  "10": "Payment Network Specific",
  "11": "Payment Network Specific (PAN)",
  "12": "Payment Network Specific",
  "13": "Payment Network Specific",
  "14": "Payment Network Specific",
  "15": "Payment Network Specific",
  "16": "Payment Network Specific",
  "17": "Payment Network Specific (Merchant ID)",
  "18": "Payment Network Specific",
  "19": "Payment Network Specific",
  "20": "Payment Network Specific",
  "21": "Payment Network Specific",
  "22": "Payment Network Specific",
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
    this.feePercent,
    this.feeFixed,
    this.tipIndicator,
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
  final String? feePercent;
  final String? feeFixed;
  final String? tipIndicator;
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
    push("Tip", tipIndicator);
    push("Fee (Fixed)", feeFixed);
    push("Fee (%)", feePercent);
    push("Country", country);
    push("CRC", "$crc (${crcIsValid == true ? 'valid' : 'INVALID ${crcComputed ?? ''}'})");
    if (additionalData != null) {
      for (final e in additionalData!.entries) {
        final v = e.value as Map<String, dynamic>;
        rows.add('${(v['name'] as String).padRight(18)}: ${v['value']}');
      }
    }
    if (merchantAccount != null) {
      for (final acct in merchantAccount!) {
        final fields = acct['fields'] as List;
        rows.add('${"--- Tag ${acct['tag']} ---".padRight(18)}');
        for (final f in fields) {
          final m = f as Map<String, dynamic>;
          rows.add('  ${(m['name'] as String).padRight(16)}: ${m['value']}');
        }
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
      .map((e) => {
        "tag": e.tag,
        "fields": parseTLV(e.value).map((f) => {
          "tag": f.tag,
          "name": merchantSubtagNames[f.tag] ?? f.name,
          "length": f.length,
          "value": f.value,
        }).toList(),
      })
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
    tipIndicator: map["55"],
    feeFixed: map["56"],
    feePercent: map["57"],
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

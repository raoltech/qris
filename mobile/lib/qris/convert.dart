import 'crc.dart';
import 'tlv.dart';

String makeString(String qris, {String? nominal, String taxtype = "p", String fee = "0"}) {
  if (qris.isEmpty) throw ArgumentError('Parameter "qris" wajib diisi.');
  if (nominal == null || nominal.isEmpty) throw ArgumentError('Parameter "nominal" wajib diisi.');
  String tax = "";
  String modified = qris.substring(0, qris.length - 4).replaceAll("010211", "010212");
  final parts = modified.split("5802ID");
  final amount = "54" + pad2(nominal.length.toString()) + nominal;
  if (taxtype.isNotEmpty && fee.isNotEmpty) {
    tax = taxtype == "p"
        ? "55020257" + pad2(fee.length.toString()) + fee
        : "55020156" + pad2(fee.length.toString()) + fee;
  }
  final glued = tax.isEmpty ? "5802ID" : tax + "5802ID";
  final output = parts[0].trim() + amount + glued + parts[1].trim();
  return output + toCRC16(output);
}

String setAmount(String qris, String nominal) => makeString(qris, nominal: nominal);

const Set<String> guardedTags = {"53", "58"};

String _encodeTLV(String tag, String value) => tag + pad2(value.length.toString()) + value;

String setField(String qris, String tag, String value, {bool allowGuarded = false}) {
  if (qris.isEmpty) throw ArgumentError('Parameter "qris" wajib diisi.');
  if (!RegExp(r'^\d{2}$').hasMatch(tag)) throw ArgumentError("Tag harus 2 digit.");
  if (guardedTags.contains(tag) && !allowGuarded) {
    throw ArgumentError("Tag $tag adalah field sistem (currency/country).");
  }
  final body = qris.substring(0, qris.length - 4);
  final elements = parseTLV(body);
  final target = elements.where((e) => e.tag == tag).isEmpty ? null : elements.firstWhere((e) => e.tag == tag);
  late String out;
  if (target != null) {
    final oldBlock = tag + pad2(target.length.toString()) + target.value;
    out = body.replaceFirst(oldBlock, _encodeTLV(tag, value));
  } else {
    out = body + _encodeTLV(tag, value);
  }
  return out + toCRC16(out);
}

String setMerchantCity(String qris, String city) => setField(qris, "60", city);
String setMerchantName(String qris, String name) => setField(qris, "59", name);

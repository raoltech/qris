import 'tlv.dart';

class Merchant {
  Merchant({
    required this.id,
    this.name,
    this.merchantName,
    this.city,
    this.currency,
    this.crcValid,
  });
  final String id;
  final String? name;
  final String? merchantName;
  final String? city;
  final String? currency;
  final bool? crcValid;
}

class MerchantRegistry {
  final Map<String, Merchant> _merchants = {};

  Merchant add(String id, {required String qris, String? name}) {
    final parsed = parseQRIS(qris);
    if (!parsed.crcIsValid!) throw ArgumentError("QRIS tidak valid (CRC mismatch)");
    final m = Merchant(
      id: id,
      name: name ?? parsed.merchantName,
      merchantName: parsed.merchantName,
      city: parsed.merchantCity,
      currency: parsed.currency,
      crcValid: parsed.crcIsValid,
    );
    _merchants[id] = m;
    return m;
  }

  Merchant? get(String id) => _merchants[id];
  List<Merchant> list() => _merchants.values.toList();
}

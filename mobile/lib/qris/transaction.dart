import 'dart:math';
import 'convert.dart';
import 'tlv.dart';

class Transaction {
  Transaction({
    required this.ref,
    required this.nominal,
    this.customerName,
    this.description,
    this.fee = 0,
    this.taxtype = "p",
    required this.qrisString,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.paidAt,
    this.paidMethod,
  });

  final String ref;
  final int nominal;
  final String? customerName;
  final String? description;
  final int fee;
  final String taxtype;
  final String qrisString;
  String status;
  final String createdAt;
  final String expiresAt;
  String? paidAt;
  String? paidMethod;
}

class TransactionStore {
  TransactionStore({this.ttlMs = 15 * 60 * 1000});
  final int ttlMs;
  final Map<String, Transaction> _map = {};

  Transaction create({
    required String qris,
    required String nominal,
    String? customerName,
    String? description,
    String fee = "0",
    String taxtype = "p",
    String? city,
    String? name,
    String refPrefix = "RAOL",
  }) {
    String base = qris;
    if (city != null) base = setMerchantCity(base, city);
    if (name != null) base = setMerchantName(base, name);
    final qrisString = makeString(base, nominal: nominal, fee: fee, taxtype: taxtype);
    final ref = refPrefix +
        DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase() +
        Random().nextInt(65535).toRadixString(16).toUpperCase().padLeft(4, '0');
    final now = DateTime.now();
    final tx = Transaction(
      ref: ref,
      nominal: int.parse(nominal),
      customerName: customerName,
      description: description,
      fee: int.tryParse(fee) ?? 0,
      taxtype: taxtype,
      qrisString: qrisString,
      status: "pending",
      createdAt: now.toIso8601String(),
      expiresAt: now.add(Duration(milliseconds: ttlMs)).toIso8601String(),
    );
    _map[ref] = tx;
    return tx;
  }

  Transaction? get(String ref) {
    final tx = _map[ref];
    if (tx == null) return null;
    if (tx.status == "pending" && DateTime.now().isAfter(DateTime.parse(tx.expiresAt))) {
      tx.status = "expired";
    }
    return tx;
  }

  Transaction? confirm(String ref, {String method = "manual"}) {
    final tx = _map[ref];
    if (tx == null) return null;
    if (tx.status == "expired") throw ArgumentError("transaksi sudah expired");
    tx.status = "paid";
    tx.paidAt = DateTime.now().toIso8601String();
    tx.paidMethod = method;
    return tx;
  }

  List<Transaction> list({String? status}) {
    final all = _map.values.toList();
    return status == null ? all : all.where((t) => t.status == status).toList();
  }
}

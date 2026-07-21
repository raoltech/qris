import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsEntry {
  DateTime date;
  int nominal;
  String note;

  SavingsEntry({required this.date, required this.nominal, this.note = ''});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'nominal': nominal,
    'note': note,
  };

  factory SavingsEntry.fromJson(Map<String, dynamic> j) => SavingsEntry(
    date: DateTime.parse(j['date']),
    nominal: j['nominal'],
    note: j['note'] ?? '',
  );

  String get dateStr => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class SavingsService {
  static const _kMerchantQris = 'merchant_qris';
  static const _kMerchantName = 'merchant_name';
  static const _kMerchantCity = 'merchant_city';
  static const _kTarget = 'savings_target';
  static const _kEntries = 'savings_entries';
  static const _kTimeout = 'qris_timeout';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<String> getMerchantQris() async => (await _prefs).getString(_kMerchantQris) ?? '';
  static Future<void> setMerchantQris(String v) async => (await _prefs).setString(_kMerchantQris, v);

  static Future<String> getMerchantName() async => (await _prefs).getString(_kMerchantName) ?? '';
  static Future<void> setMerchantName(String v) async => (await _prefs).setString(_kMerchantName, v);

  static Future<String> getMerchantCity() async => (await _prefs).getString(_kMerchantCity) ?? '';
  static Future<void> setMerchantCity(String v) async => (await _prefs).setString(_kMerchantCity, v);

  static Future<int> getTarget() async => (await _prefs).getInt(_kTarget) ?? 0;
  static Future<void> setTarget(int v) async => (await _prefs).setInt(_kTarget, v);

  static Future<int> getTimeout() async => (await _prefs).getInt(_kTimeout) ?? 15;
  static Future<void> setTimeout(int v) async => (await _prefs).setInt(_kTimeout, v);

  static Future<List<SavingsEntry>> getEntries() async {
    final raw = (await _prefs).getString(_kEntries);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => SavingsEntry.fromJson(e)).toList();
  }

  static Future<void> saveEntry(SavingsEntry entry) async {
    final entries = await getEntries();
    entries.add(entry);
    entries.sort((a, b) => b.date.compareTo(a.date));
    await (await _prefs).setString(_kEntries, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteEntry(int index) async {
    final entries = await getEntries();
    if (index < entries.length) {
      entries.removeAt(index);
      await (await _prefs).setString(_kEntries, jsonEncode(entries.map((e) => e.toJson()).toList()));
    }
  }

  static Future<void> clearAll() async {
    await (await _prefs).remove(_kEntries);
  }
}
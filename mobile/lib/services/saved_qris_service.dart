import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SavedQris {
  final String id;
  String alias;
  String qrisString;
  String merchantName;
  String merchantCity;
  DateTime savedAt;

  SavedQris({
    required this.id,
    required this.alias,
    required this.qrisString,
    this.merchantName = '',
    this.merchantCity = '',
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'alias': alias,
    'qrisString': qrisString,
    'merchantName': merchantName,
    'merchantCity': merchantCity,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedQris.fromJson(Map<String, dynamic> j) => SavedQris(
    id: j['id'],
    alias: j['alias'] ?? '',
    qrisString: j['qrisString'],
    merchantName: j['merchantName'] ?? '',
    merchantCity: j['merchantCity'] ?? '',
    savedAt: DateTime.tryParse(j['savedAt'] ?? ''),
  );
}

class SavedQrisService {
  static List<SavedQris> _cache = [];
  static bool _loaded = false;

  static Future<String> get _path async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/saved_qris.json';
  }

  static Future<List<SavedQris>> getAll() async {
    if (_loaded) return _cache;
    try {
      final file = File(await _path);
      if (!file.existsSync()) return _cache;
      final raw = jsonDecode(await file.readAsString()) as List;
      _cache = raw.map((e) => SavedQris.fromJson(e)).toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {}
    _loaded = true;
    return _cache;
  }

  static Future<void> save(SavedQris entry) async {
    final all = await getAll();
    final idx = all.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      all[idx] = entry;
    } else {
      all.insert(0, entry);
    }
    _cache = all;
    await _write(all);
  }

  static Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((e) => e.id == id);
    _cache = all;
    await _write(all);
  }

  static Future<SavedQris?> get(String id) async {
    final all = await getAll();
    return all.where((e) => e.id == id).isEmpty ? null : all.firstWhere((e) => e.id == id);
  }

  static Future<void> _write(List<SavedQris> list) async {
    final file = File(await _path);
    await file.writeAsString(jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
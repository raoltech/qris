import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../qris/index.dart';
import '../services/qr_render.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _base = TextEditingController(
      text:
          "00020101021126570011ID.DANA.WWW011893600915303023251702090302325170303UMI51440014ID.CO.QRIS.WWW0215ID10265294489570303UMI5204737253033605802ID5914Raol Mukarrozi6015Kota Banjar Bar6105707316304E0BD");
  final _name = TextEditingController(text: "TOKO NEOBRUTAL");
  final _city = TextEditingController(text: "BANDUNG");
  final _nominal = TextEditingController(text: "100000");
  final _fee = TextEditingController(text: "0");
  final _timeout = TextEditingController(text: "15");

  String? _qrisString;
  ParsedQRIS? _parsed;
  Uint8List? _qrBytes;
  String? _savedPath;
  String? _error;

  Future<void> _generate() async {
    try {
      String q = _base.text.trim();
      if (_name.text.isNotEmpty) q = setMerchantName(q, _name.text);
      if (_city.text.isNotEmpty) q = setMerchantCity(q, _city.text);
      q = makeString(q, nominal: _nominal.text, fee: _fee.text, taxtype: "p");
      final parsed = parseQRIS(q);
      final bytes = await QrRender.toJpg(q, size: 480);
      setState(() {
        _qrisString = q;
        _parsed = parsed;
        _qrBytes = bytes;
        _error = null;
        _savedPath = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _saveJpg() async {
    if (_qrBytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = await File('${dir.path}/qris-${_nominal.text}.jpg').writeAsBytes(_qrBytes!);
    setState(() => _savedPath = file.path);
    await Share.shareXFiles([XFile(file.path)], text: "QRIS ${_nominal.text}");
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field("Base QRIS", _base, maxLines: 3),
          _field("Nama Merchant", _name),
          _field("Kota", _city),
          _field("Nominal (IDR)", _nominal),
          _field("Fee %", _fee),
          _field("Timeout (menit)", _timeout),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.qr_code_2),
            label: const Text("GENERATE"),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text("Error: $_error", style: const TextStyle(color: Colors.red)),
          ],
          if (_qrBytes != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.memory(_qrBytes!),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _saveJpg,
              icon: const Icon(Icons.save_alt),
              label: const Text("SAVE JPG"),
            ),
            if (_savedPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Saved: $_savedPath", style: const TextStyle(color: Colors.white60)),
              ),
            const SizedBox(height: 10),
            if (_parsed != null)
              Text("Mode: ${_parsed!.initiationMode} | Amount: ${_parsed!.amount ?? '-'} | CRC: ${_parsed!.crcIsValid == true ? 'valid' : 'INVALID'}",
                  style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            if (_qrisString != null) ...[
              Text("Expired: ${DateTime.now().add(Duration(minutes: int.tryParse(_timeout.text) ?? 15)).hour.toString().padLeft(2, '0')}:${DateTime.now().add(Duration(minutes: int.tryParse(_timeout.text) ?? 15)).minute.toString().padLeft(2, '0')} WIB",
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              SelectableText(_qrisString!, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
            ],
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}

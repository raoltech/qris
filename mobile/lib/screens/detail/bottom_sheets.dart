import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../qris/index.dart';
import '../../services/qr_render.dart';

class GenerateQrSheet extends StatefulWidget {
  final String baseQris;
  final int initialTimeout;
  const GenerateQrSheet({super.key, required this.baseQris, this.initialTimeout = 15});

  @override
  State<GenerateQrSheet> createState() => _GenerateQrSheetState();
}

class _GenerateQrSheetState extends State<GenerateQrSheet> {
  final _nominalCtl = TextEditingController();
  final _timeoutCtl = TextEditingController();
  Uint8List? _qrImage;
  String? _generatedQris;
  String? _error;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _timeoutCtl.text = widget.initialTimeout.toString();
  }

  @override
  void dispose() {
    _nominalCtl.dispose();
    _timeoutCtl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final nominal = int.tryParse(_nominalCtl.text);
    if (nominal == null || nominal <= 0) {
      setState(() => _error = "Nominal tidak valid");
      return;
    }
    setState(() { _error = null; _generating = true; });
    try {
      final gen = makeString(widget.baseQris, nominal: nominal.toString());
      final bytes = await QrRender.toJpg(gen);
      setState(() { _qrImage = bytes; _generatedQris = gen; _generating = false; });
    } catch (e) {
      setState(() { _error = "Gagal generate: $e"; _generating = false; });
    }
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if ((s.length - i) % 3 == 0 && i > 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  String _expiry() {
    final mnt = int.tryParse(_timeoutCtl.text) ?? 15;
    final t = DateTime.now().add(Duration(minutes: mnt));
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFB84D).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.payments, color: Color(0xFFFFB84D), size: 22),
              ),
              const SizedBox(width: 10),
              Text("Generate QR", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nominalCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Nominal (Rp)", hintText: "50000", prefixIcon: Icon(Icons.monetization_on, size: 20)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeoutCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Timeout (menit)", hintText: "15", suffixText: "menit",
              prefixIcon: Icon(Icons.timer, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          if (_qrImage != null && _generatedQris != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Image.memory(_qrImage!, width: 180, height: 180),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text("Rp ${_fmt(int.tryParse(_nominalCtl.text) ?? 0)}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB84D))),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text("Kadaluwarsa ${_expiry()} WIB",
                    style: const TextStyle(fontSize: 13, color: Colors.red.shade300, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: SelectableText(_generatedQris!, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.white54)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedQris!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QRIS disalin")));
                    },
                    label: const Text("Salin"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.save_alt, size: 18),
                    onPressed: () async {
                      try {
                        final dir = await getApplicationDocumentsDirectory();
                        final file = await File('${dir.path}/tabuqr-${DateTime.now().millisecondsSinceEpoch}.jpg').writeAsBytes(_qrImage!);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tersimpan: ${file.path}")));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                      }
                    },
                    label: const Text("Simpan JPG"),
                  ),
                ),
              ],
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _generating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.qr_code, size: 20),
                onPressed: _generating ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB84D),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                label: Text(_generating ? "Memproses..." : "GENERATE QR"),
              ),
            ),
        ],
      ),
    );
  }
}

class EditMerchantSheet extends StatefulWidget {
  final String currentQris;
  final String? merchantName;
  final String? merchantCity;
  const EditMerchantSheet({super.key, required this.currentQris, this.merchantName, this.merchantCity});

  @override
  State<EditMerchantSheet> createState() => _EditMerchantSheetState();
}

class _EditMerchantSheetState extends State<EditMerchantSheet> {
  late TextEditingController _nameCtl;
  late TextEditingController _cityCtl;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.merchantName ?? '');
    _cityCtl = TextEditingController(text: widget.merchantCity ?? '');
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _cityCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFB84D).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.store, color: Color(0xFFFFB84D), size: 22),
              ),
              const SizedBox(width: 10),
              Text("Ubah Merchant", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: "Nama Merchant", prefixIcon: Icon(Icons.badge, size: 20))),
          const SizedBox(height: 12),
          TextField(controller: _cityCtl, decoration: const InputDecoration(labelText: "Kota", prefixIcon: Icon(Icons.location_city, size: 20))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                String q = widget.currentQris;
                if (_nameCtl.text.trim().isNotEmpty) q = setMerchantName(q, _nameCtl.text.trim());
                if (_cityCtl.text.trim().isNotEmpty) q = setMerchantCity(q, _cityCtl.text.trim());
                Navigator.pop(context, q);
              },
              child: const Text("Simpan"),
            ),
          ),
        ],
      ),
    );
  }
}

class WebhookSheet extends StatefulWidget {
  final String? url;
  final String? secret;
  const WebhookSheet({super.key, this.url, this.secret});

  @override
  State<WebhookSheet> createState() => _WebhookSheetState();
}

class _WebhookSheetState extends State<WebhookSheet> {
  late TextEditingController _urlCtl;
  late TextEditingController _secretCtl;

  @override
  void initState() {
    super.initState();
    _urlCtl = TextEditingController(text: widget.url ?? '');
    _secretCtl = TextEditingController(text: widget.secret ?? '');
  }

  @override
  void dispose() {
    _urlCtl.dispose();
    _secretCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFB84D).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.webhook, color: Color(0xFFFFB84D), size: 22),
              ),
              const SizedBox(width: 10),
              Text("Webhook", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text("Notifikasi saat pembayaran dikonfirmasi.", style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(controller: _urlCtl, decoration: const InputDecoration(
            labelText: "Callback URL", hintText: "https://example.com/webhook",
            prefixIcon: Icon(Icons.link, size: 20),
          )),
          const SizedBox(height: 12),
          TextField(controller: _secretCtl, decoration: const InputDecoration(
            labelText: "Secret Key", hintText: "opsional",
            prefixIcon: Icon(Icons.lock, size: 20),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {'url': _urlCtl.text.trim(), 'secret': _secretCtl.text.trim()}),
              child: const Text("Simpan"),
            ),
          ),
        ],
      ),
    );
  }
}
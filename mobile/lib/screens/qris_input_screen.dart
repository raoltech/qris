import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../qris/index.dart';
import 'qris_detail_screen.dart';

class QrisInputScreen extends StatefulWidget {
  const QrisInputScreen({super.key});

  @override
  State<QrisInputScreen> createState() => _QrisInputScreenState();
}

class _QrisInputScreenState extends State<QrisInputScreen> {
  final _ctl = TextEditingController();
  String? _error;

  static const _danaSample = "00020101021126570011ID.DANA.WWW011893600915303023251702090302325170303UMI51440014ID.CO.QRIS.WWW0215ID10265294489570303UMI5204737253033605802ID5914Raol Mukarrozi6015Kota Banjar Bar6105707316304E0BD";

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _parse() {
    final qris = _ctl.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (qris.length < 20) {
      setState(() => _error = "QRIS terlalu pendek. Masukkan string QRIS yang valid.");
      return;
    }
    try {
      final parsed = parseQRIS(qris);
      setState(() => _error = null);
      Navigator.push(context, MaterialPageRoute(builder: (_) => QrisDetailScreen.fromParent(qris)));
    } catch (e) {
      setState(() => _error = "Gagal parse: $e");
    }
  }

  void _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _ctl.text = data.text!;
      _parse();
    }
  }

  void _scan() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur scan kamera akan segera hadir")));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("QRIS Tools")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Masukkan QRIS", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Tempel atau ketik string QRIS untuk melihat detail TLV, mengatur nominal, timeout, webhook, dan menghasilkan QR pembayaran.", style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctl,
              maxLines: 5,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: "Tempel QRIS di sini...",
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    onPressed: _parse,
                    label: const Text("PARSE QRIS"),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.paste, size: 20),
                  label: const Text("Tempel"),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text("Scan"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  _ctl.text = _danaSample;
                  _parse();
                },
                child: const Text("Gunakan QRIS contoh (Dana)", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
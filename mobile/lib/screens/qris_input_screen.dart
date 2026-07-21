import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../qris/index.dart';
import '../services/saved_qris_service.dart';
import 'qris_detail_screen.dart';
import 'qris_scan_screen.dart';

class QrisInputScreen extends StatefulWidget {
  const QrisInputScreen({super.key});

  @override
  State<QrisInputScreen> createState() => _QrisInputScreenState();
}

class _QrisInputScreenState extends State<QrisInputScreen> {
  final _ctl = TextEditingController();
  String? _error;
  List<SavedQris> _saved = [];

  static const _danaSample = "00020101021126570011ID.DANA.WWW011893600915303023251702090302325170303UMI51440014ID.CO.QRIS.WWW0215ID10265294489570303UMI5204737253033605802ID5914Raol Mukarrozi6015Kota Banjar Bar6105707316304E0BD";

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    _saved = await SavedQrisService.getAll();
    if (mounted) setState(() {});
  }

  void _parse({String? qris}) {
    final input = (qris ?? _ctl.text).trim().replaceAll(RegExp(r'\s+'), '');
    if (input.length < 20) {
      setState(() => _error = "QRIS terlalu pendek. Masukkan string QRIS yang valid.");
      return;
    }
    try {
      parseQRIS(input);
      setState(() => _error = null);
      Navigator.push(context, MaterialPageRoute(builder: (_) => QrisDetailScreen(qrisString: input)));
    } catch (e) {
      setState(() => _error = "Gagal parse: $e");
    }
  }

  void _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _ctl.text = data.text!;
      _parse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("QRIS Tools")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFFFB84D).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.qr_code_2, color: Color(0xFFFFB84D), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text("Masukkan QRIS", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text("Tempel atau ketik string QRIS. Bisa juga pilih dari daftar tersimpan di bawah.", style: TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctl,
              maxLines: 4,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: "Tempel QRIS di sini...",
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    onPressed: () => _parse(),
                    label: const Text("PARSE QRIS"),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.paste, size: 18),
                  label: const Text("Tempel"),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrisScanScreen()));
                    if (result != null) _parse(qris: result);
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text("Scan"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _parse(qris: _danaSample),
                child: const Text("Gunakan QRIS contoh (Dana)", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
            if (_saved.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.bookmark, size: 18, color: Color(0xFFFFB84D)),
                  const SizedBox(width: 8),
                  Text("QRIS Tersimpan", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ..._saved.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _parse(qris: s.qrisString),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFF4A6CF7).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.qr_code, size: 18, color: Color(0xFF4A6CF7)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.alias.isNotEmpty ? s.alias : "QRIS ${s.id.substring(0, 6)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(s.qrisString.substring(0, 30), style: const TextStyle(fontSize: 11, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
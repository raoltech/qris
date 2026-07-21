import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../qris/index.dart';
import '../services/qr_render.dart';

class QrisDetailScreen extends StatefulWidget {
  final String qrisString;
  const QrisDetailScreen({super.key, required this.qrisString});

  factory QrisDetailScreen.fromParent(String qris) => QrisDetailScreen(qrisString: qris);

  @override
  State<QrisDetailScreen> createState() => _QrisDetailScreenState();
}

class _QrisDetailScreenState extends State<QrisDetailScreen> {
  late ParsedQRIS _parsed;
  late String _currentQris;
  int _timeoutMnt = 15;
  String? _webhookUrl;
  String? _webhookSecret;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _currentQris = widget.qrisString;
    _parsed = parseQRIS(_currentQris);
  }

  void _reparse() {
    setState(() {
      _parsed = parseQRIS(_currentQris);
    });
  }

  void _copyQris() {
    Clipboard.setData(ClipboardData(text: _currentQris));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QRIS disalin ke clipboard")));
  }

  void _showGenerateSheet() {
    final nominalCtl = TextEditingController();
    final timeoutCtl = TextEditingController(text: _timeoutMnt.toString());
    Uint8List? qrImage;
    String? generatedQris;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Generate QR Pembayaran", style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nominalCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Nominal (Rp)", hintText: "50000"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeoutCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Timeout (menit)", hintText: "15", suffixText: "menit"),
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                if (qrImage != null && generatedQris != null) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Image.memory(qrImage!, width: 200, height: 200),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Rp ${_formatNominal(int.tryParse(nominalCtl.text) ?? 0)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFB84D)),
                    ),
                  ),
                  Center(
                    child: Text(
                      "Kadaluwarsa ${_expiryStr(_timeoutMnt)} WIB",
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(generatedQris!, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.white54)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: generatedQris!));
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("QRIS disalin")));
                          },
                          label: const Text("Salin QRIS"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_alt, size: 18),
                          onPressed: () async {
                            await _saveJpg(generatedQris!, qrImage!, ctx);
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
                      onPressed: _generating
                          ? null
                          : () async {
                              final nominal = int.tryParse(nominalCtl.text);
                              if (nominal == null || nominal <= 0) {
                                setSheetState(() => error = "Nominal tidak valid");
                                return;
                              }
                              setSheetState(() {
                                error = null;
                                _generating = true;
                              });
                              try {
                                final t = int.tryParse(timeoutCtl.text) ?? 15;
                                _timeoutMnt = t;
                                final gen = makeString(_currentQris, nominal: nominal.toString());
                                final bytes = await QrRender.toJpg(gen);
                                setSheetState(() {
                                  qrImage = bytes;
                                  generatedQris = gen;
                                  _generating = false;
                                });
                              } catch (e) {
                                setSheetState(() {
                                  error = "Gagal generate: $e";
                                  _generating = false;
                                });
                              }
                            },
                      label: Text(_generating ? "Memproses..." : "GENERATE QR"),
                    ),
                  ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showEditMerchantSheet() {
    final nameCtl = TextEditingController(text: _parsed.merchantName ?? '');
    final cityCtl = TextEditingController(text: _parsed.merchantCity ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ubah Merchant", style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: "Nama Merchant")),
              const SizedBox(height: 12),
              TextField(controller: cityCtl, decoration: const InputDecoration(labelText: "Kota")),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String q = _currentQris;
                    if (nameCtl.text.trim().isNotEmpty) q = setMerchantName(q, nameCtl.text.trim());
                    if (cityCtl.text.trim().isNotEmpty) q = setMerchantCity(q, cityCtl.text.trim());
                    setState(() {
                      _currentQris = q;
                      _parsed = parseQRIS(_currentQris);
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Merchant diperbarui")));
                  },
                  child: const Text("Simpan"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWebhookSheet() {
    final urlCtl = TextEditingController(text: _webhookUrl ?? '');
    final secretCtl = TextEditingController(text: _webhookSecret ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Webhook", style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Notifikasi pembayaran otomatis saat QRIS dipindai.", style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(controller: urlCtl, decoration: const InputDecoration(labelText: "Callback URL", hintText: "https://example.com/webhook")),
              const SizedBox(height: 12),
              TextField(controller: secretCtl, decoration: const InputDecoration(labelText: "Secret Key", hintText: "opsional")),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _webhookUrl = urlCtl.text.trim();
                      _webhookSecret = secretCtl.text.trim();
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Webhook disimpan")));
                  },
                  child: const Text("Simpan Webhook"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveJpg(String qris, Uint8List bytes, BuildContext ctx) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = await File('${dir.path}/tabuqr-${DateTime.now().millisecondsSinceEpoch}.jpg').writeAsBytes(bytes);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Tersimpan: ${file.path}")));
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Gagal simpan: $e")));
    }
  }

  String _formatNominal(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if ((s.length - i) % 3 == 0 && i > 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  String _expiryStr(int mnt) {
    final t = DateTime.now().add(Duration(minutes: mnt));
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _parsed;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail QRIS"),
        actions: [
          IconButton(icon: const Icon(Icons.copy), onPressed: _copyQris, tooltip: "Salin QRIS"),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _currentQris = widget.qrisString;
              _reparse();
            },
            tooltip: "Reset ke QRIS awal",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QrisStringCard(qris: _currentQris, onCopy: _copyQris),
            const SizedBox(height: 12),
            _StatusCard(p: p, theme: theme),
            const SizedBox(height: 12),
            if (p.merchantName != null || p.merchantCity != null)
              _MerchantCard(p: p, theme: theme),
            if (p.amount != null || p.initiationMode != null) ...[
              const SizedBox(height: 12),
              _TransactionCard(p: p, theme: theme),
            ],
            const SizedBox(height: 12),
            _TlvCard(raw: p.raw ?? [], theme: theme),
            const SizedBox(height: 12),
            _ActionsCard(
              onGenerate: _showGenerateSheet,
              onEditMerchant: _showEditMerchantSheet,
              onWebhook: _showWebhookSheet,
              onCopy: _copyQris,
              theme: theme,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── CARD WIDGETS ───

class _QrisStringCard extends StatelessWidget {
  final String qris;
  final VoidCallback onCopy;
  const _QrisStringCard({required this.qris, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code, size: 18, color: Color(0xFFFFB84D)),
                const SizedBox(width: 8),
                const Expanded(child: Text("String QRIS", style: TextStyle(fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.copy, size: 16), onPressed: onCopy, tooltip: "Salin"),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(qris, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ParsedQRIS p;
  final ThemeData theme;
  const _StatusCard({required this.p, required this.theme});

  @override
  Widget build(BuildContext context) {
    final valid = p.crcIsValid == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (valid ? Colors.green : Colors.red).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(valid ? Icons.check_circle : Icons.warning, color: valid ? Colors.green : Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valid ? "QRIS VALID" : "QRIS TIDAK VALID", style: TextStyle(fontWeight: FontWeight.bold, color: valid ? Colors.green : Colors.red)),
                  const SizedBox(height: 2),
                  Text("CRC: ${p.crc ?? '-'}${p.crcComputed != null ? ' (hitung: ${p.crcComputed})' : ''}", style: const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB84D).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(p.initiationMode ?? '-', style: const TextStyle(fontSize: 12, color: Color(0xFFFFB84D), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  final ParsedQRIS p;
  final ThemeData theme;
  const _MerchantCard({required this.p, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, size: 18, color: Color(0xFFFFB84D)),
                const SizedBox(width: 8),
                const Text("Merchant", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow("Nama", p.merchantName ?? '-'),
            _infoRow("Kota", p.merchantCity ?? '-'),
            _infoRow("Kode Pos", p.postalCode ?? '-'),
            _infoRow("Kategori", p.merchantCategoryCode ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final ParsedQRIS p;
  final ThemeData theme;
  const _TransactionCard({required this.p, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, size: 18, color: Color(0xFFFFB84D)),
                const SizedBox(width: 8),
                const Text("Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow("Mata Uang", p.currency == "360" ? "IDR (360)" : (p.currency ?? '-')),
            _infoRow("Nominal", p.amount != null ? "Rp ${_fmt(p.amount!)}" : "Belum diisi (statis)"),
            _infoRow("Negara", p.country ?? '-'),
            _infoRow("Payload", p.formatIndicator ?? '-'),
          ],
        ),
      ),
    );
  }

  String _fmt(String n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if ((s.length - i) % 3 == 0 && i > 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _TlvCard extends StatelessWidget {
  final List<TlvEntry> raw;
  final ThemeData theme;
  const _TlvCard({required this.raw, required this.theme});

  @override
  Widget build(BuildContext context) {
    final inner = raw.where((e) => e.tag != "26" && e.tag != "62").toList();
    final additional = raw.where((e) => e.tag == "26" || e.tag == "27" || e.tag == "28").toList();
    final data62 = raw.where((e) => e.tag == "62").toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, size: 18, color: Color(0xFFFFB84D)),
                const SizedBox(width: 8),
                const Text("TLV", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ...inner.map((e) => _tlvRow(e)),
            if (additional.isNotEmpty) ...[
              const Divider(color: Colors.white12),
              const Text("Merchant Account (26-51)", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ...additional.map((e) => _tlvRow(e)),
            ],
            if (data62.isNotEmpty) ...[
              const Divider(color: Colors.white12),
              const Text("Additional Data (62)", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ...data62.map((e) => _tlvRow(e)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tlvRow(TlvEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF4A6CF7).withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
            child: Text(e.tag, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(e.name, style: const TextStyle(fontSize: 12, color: Colors.white60), overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(e.value, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
          Text("(${e.length})", style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final VoidCallback onGenerate;
  final VoidCallback onEditMerchant;
  final VoidCallback onWebhook;
  final VoidCallback onCopy;
  final ThemeData theme;
  const _ActionsCard({required this.onGenerate, required this.onEditMerchant, required this.onWebhook, required this.onCopy, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app, size: 18, color: Color(0xFFFFB84D)),
                const SizedBox(width: 8),
                const Text("Aksi", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            _actionBtn(Icons.payments, "Generate QR Pembayaran", "Atur nominal & timeout, hasilkan QR", onGenerate),
            const Divider(color: Colors.white12, height: 16),
            _actionBtn(Icons.store, "Ubah Merchant", "Ganti nama & kota merchant", onEditMerchant),
            const Divider(color: Colors.white12, height: 16),
            _actionBtn(Icons.webhook, "Webhook", "Konfigurasi callback URL & secret", onWebhook),
            const Divider(color: Colors.white12, height: 16),
            _actionBtn(Icons.copy, "Salin QRIS", "Copy string QRIS ke clipboard", onCopy),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String title, String desc, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF4A6CF7).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 20, color: const Color(0xFF4A6CF7)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
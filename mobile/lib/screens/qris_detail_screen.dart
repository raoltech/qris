import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../qris/index.dart';
import '../services/saved_qris_service.dart';
import 'detail/bottom_sheets.dart';

class QrisDetailScreen extends StatefulWidget {
  final String qrisString;
  const QrisDetailScreen({super.key, required this.qrisString});

  @override
  State<QrisDetailScreen> createState() => _QrisDetailScreenState();
}

class _QrisDetailScreenState extends State<QrisDetailScreen> {
  late ParsedQRIS _parsed;
  late String _currentQris;
  int _timeoutMnt = 15;
  String? _webhookUrl;
  String? _webhookSecret;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _currentQris = widget.qrisString;
    _parsed = parseQRIS(_currentQris);
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final all = await SavedQrisService.getAll();
    _isSaved = all.any((e) => e.qrisString == _currentQris);
    if (mounted) setState(() {});
  }

  void _reparse() => setState(() => _parsed = parseQRIS(_currentQris));

  void _copyQris() {
    Clipboard.setData(ClipboardData(text: _currentQris));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QRIS disalin")));
  }

  Future<void> _toggleSave() async {
    final all = await SavedQrisService.getAll();
    final existing = all.where((e) => e.qrisString == _currentQris);
    if (existing.isNotEmpty) {
      await SavedQrisService.delete(existing.first.id);
      if (mounted) setState(() => _isSaved = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dihapus dari tersimpan")));
    } else {
      await SavedQrisService.save(SavedQris(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        alias: _parsed.merchantName ?? 'QRIS ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        qrisString: _currentQris,
        merchantName: _parsed.merchantName ?? '',
        merchantCity: _parsed.merchantCity ?? '',
      ));
      if (mounted) setState(() => _isSaved = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QRIS tersimpan")));
    }
  }

  void _showGenerateSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => GenerateQrSheet(baseQris: _currentQris, initialTimeout: _timeoutMnt),
    );
  }

  void _showEditMerchantSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => EditMerchantSheet(currentQris: _currentQris, merchantName: _parsed.merchantName, merchantCity: _parsed.merchantCity),
    );
    if (result != null) {
      setState(() { _currentQris = result; _parsed = parseQRIS(_currentQris); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Merchant diperbarui")));
    }
  }

  void _showWebhookSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => WebhookSheet(url: _webhookUrl, secret: _webhookSecret),
    );
    if (result != null) {
      setState(() { _webhookUrl = result['url']; _webhookSecret = result['secret']; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_webhookUrl!.isNotEmpty ? "Webhook disimpan" : "Webhook dikosongkan")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _parsed;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail QRIS"),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? const Color(0xFFFFB84D) : null),
            onPressed: _toggleSave,
            tooltip: _isSaved ? "Hapus dari tersimpan" : "Simpan QRIS",
          ),
          IconButton(icon: const Icon(Icons.copy), onPressed: _copyQris, tooltip: "Salin QRIS"),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QrisStringCard(qris: _currentQris, onCopy: _copyQris),
            const SizedBox(height: 12),
            _StatusCard(p: p),
            const SizedBox(height: 12),
            _MerchantCard(p: p),
            const SizedBox(height: 12),
            _TransactionCard(p: p),
            const SizedBox(height: 12),
            _TlvCard(raw: p.raw ?? []),
            const SizedBox(height: 12),
            _ActionsCard(
              onGenerate: _showGenerateSheet,
              onEditMerchant: _showEditMerchantSheet,
              onWebhook: _showWebhookSheet,
              onCopy: _copyQris,
              onSave: _toggleSave,
              isSaved: _isSaved,
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
                _iconBox(Icons.qr_code, const Color(0xFFFFB84D)),
                const SizedBox(width: 8),
                const Expanded(child: Text("String QRIS", style: TextStyle(fontWeight: FontWeight.bold))),
                _copyBtn(onCopy),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: SelectableText(qris, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ParsedQRIS p;
  const _StatusCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final valid = p.crcIsValid == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (valid ? Colors.green : Colors.red).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(valid ? Icons.check_circle : Icons.warning_amber, color: valid ? Colors.green : Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valid ? "QRIS Valid" : "QRIS Tidak Valid",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: valid ? Colors.green : Colors.red)),
                  Text("CRC: ${p.crc ?? '-'}${p.crcComputed != null && p.crc != p.crcComputed ? ' (seharusnya: ${p.crcComputed})' : ''}",
                      style: const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            _badge(p.initiationMode ?? '-'),
          ],
        ),
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  final ParsedQRIS p;
  const _MerchantCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(Icons.store, "Merchant"),
            const SizedBox(height: 12),
            _row(Icons.badge, "Nama", p.merchantName ?? '-'),
            _row(Icons.location_city, "Kota", p.merchantCity ?? '-'),
            _row(Icons.markunread_mailbox, "Kode Pos", p.postalCode ?? '-'),
            _row(Icons.category, "Kategori", p.merchantCategoryCode ?? '-'),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final ParsedQRIS p;
  const _TransactionCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(Icons.receipt, "Transaksi"),
            const SizedBox(height: 12),
            _row(Icons.monetization_on, "Mata Uang", p.currency == "360" ? "IDR (Rupiah)" : (p.currency ?? '-')),
            _row(Icons.money, "Nominal", p.amount != null ? "Rp ${_fmt(p.amount!)}" : "Belum diatur (statis)"),
            _row(Icons.flag, "Negara", p.country ?? '-'),
            _row(Icons.tag, "Format", p.formatIndicator ?? '-'),
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
}

class _TlvCard extends StatelessWidget {
  final List<TlvEntry> raw;
  const _TlvCard({required this.raw});

  @override
  Widget build(BuildContext context) {
    final main = raw.where((e) => !["26", "27", "28", "62"].contains(e.tag)).toList();
    final accounts = raw.where((e) => ["26", "27", "28"].contains(e.tag)).toList();
    final data62 = raw.where((e) => e.tag == "62").toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBox(Icons.list_alt, const Color(0xFFFFB84D)),
                const SizedBox(width: 8),
                const Text("TLV", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("${raw.length} entry", style: const TextStyle(fontSize: 12, color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 10),
            _table(main),
            if (accounts.isNotEmpty) ...[
              const Divider(color: Colors.white12, height: 20),
              const Text("Merchant Account (26-28)", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6), _table(accounts),
            ],
            if (data62.isNotEmpty) ...[
              const Divider(color: Colors.white12, height: 20),
              const Text("Additional Data (62)", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6), _table(data62),
            ],
          ],
        ),
      ),
    );
  }

  Widget _table(List<TlvEntry> entries) => Column(children: entries.map(_row).toList());

  Widget _row(TlvEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 34,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF4A6CF7).withOpacity(0.25), borderRadius: BorderRadius.circular(4)),
            child: Text(e.tag, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7))),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text(e.name, style: const TextStyle(fontSize: 12, color: Colors.white60), overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(e.value, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis, maxLines: 2)),
          const SizedBox(width: 4),
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
  final VoidCallback onSave;
  final bool isSaved;
  const _ActionsCard({required this.onGenerate, required this.onEditMerchant, required this.onWebhook, required this.onCopy, required this.onSave, required this.isSaved});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(Icons.touch_app, "Aksi"),
            const SizedBox(height: 14),
            _actionItem(Icons.payments, "Generate QR", "Nominal + timeout → QR", onGenerate),
            _divider(),
            _actionItem(Icons.store, "Ubah Merchant", "Ganti nama & kota", onEditMerchant),
            _divider(),
            _actionItem(Icons.webhook, "Webhook", "Callback URL & secret", onWebhook),
            _divider(),
            _actionItem(Icons.copy, "Salin QRIS", "Copy string ke clipboard", onCopy),
            _divider(),
            _actionItem(isSaved ? Icons.bookmark : Icons.bookmark_border,
                isSaved ? "Hapus dari Tersimpan" : "Simpan QRIS",
                isSaved ? "Hapus dari daftar" : "Simpan untuk akses cepat", onSave),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(color: Colors.white12, height: 16);

  Widget _actionItem(IconData icon, String title, String desc, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _iconBox(icon, const Color(0xFF4A6CF7)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            )),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

// ─── HELPERS ───

Widget _iconBox(IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
    child: Icon(icon, size: 16, color: color),
  );
}

Widget _copyBtn(VoidCallback onCopy) {
  return InkWell(
    borderRadius: BorderRadius.circular(6),
    onTap: onCopy,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF4A6CF7).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.copy, size: 14, color: Color(0xFF4A6CF7)),
          SizedBox(width: 4),
          Text("Salin", style: TextStyle(fontSize: 12, color: Color(0xFF4A6CF7))),
        ],
      ),
    ),
  );
}

Widget _header(IconData icon, String title) {
  return Row(
    children: [
      _iconBox(icon, const Color(0xFFFFB84D)),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _row(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(width: 8),
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}

Widget _badge(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFFFFB84D).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFFFFB84D), fontWeight: FontWeight.bold)),
  );
}
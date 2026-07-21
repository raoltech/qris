import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/savings_service.dart';
import '../qris/convert.dart';
import '../services/qr_render.dart';

class TabunganScreen extends StatefulWidget {
  const TabunganScreen({super.key});

  @override
  State<TabunganScreen> createState() => _TabunganScreenState();
}

class _TabunganScreenState extends State<TabunganScreen> {
  List<SavingsEntry> _entries = [];
  int _target = 0;
  bool _loading = true;

  final _merchantQrisCtl = TextEditingController();
  final _merchantNameCtl = TextEditingController();
  final _merchantCityCtl = TextEditingController();
  final _targetCtl = TextEditingController();
  final _nominalCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  final _timeoutCtl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _merchantExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _merchantQrisCtl.dispose();
    _merchantNameCtl.dispose();
    _merchantCityCtl.dispose();
    _targetCtl.dispose();
    _nominalCtl.dispose();
    _noteCtl.dispose();
    _timeoutCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _merchantQrisCtl.text = await SavingsService.getMerchantQris();
    _merchantNameCtl.text = await SavingsService.getMerchantName();
    _merchantCityCtl.text = await SavingsService.getMerchantCity();
    _target = await SavingsService.getTarget();
    _targetCtl.text = _target.toString();
    _timeoutCtl.text = (await SavingsService.getTimeout()).toString();
    _entries = await SavingsService.getEntries();
    setState(() => _loading = false);
  }

  Future<void> _saveMerchant() async {
    await SavingsService.setMerchantQris(_merchantQrisCtl.text.trim());
    await SavingsService.setMerchantName(_merchantNameCtl.text.trim());
    await SavingsService.setMerchantCity(_merchantCityCtl.text.trim());
    final t = int.tryParse(_targetCtl.text) ?? 0;
    _target = t;
    await SavingsService.setTarget(t);
    final timeout = int.tryParse(_timeoutCtl.text) ?? 15;
    await SavingsService.setTimeout(timeout);
    setState(() {});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Merchant disimpan")));
  }

  Future<void> _addEntry() async {
    final nominal = int.tryParse(_nominalCtl.text);
    if (nominal == null || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominal tidak valid")));
      return;
    }
    final entry = SavingsEntry(date: _selectedDate, nominal: nominal, note: _noteCtl.text.trim());
    await SavingsService.saveEntry(entry);
    _entries.insert(0, entry);
    _entries.sort((a, b) => b.date.compareTo(a.date));
    _nominalCtl.clear();
    _noteCtl.clear();
    setState(() {});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tabungan dicatat")));
  }

  Future<void> _deleteEntry(int i) async {
    await SavingsService.deleteEntry(i);
    _entries.removeAt(i);
    setState(() {});
  }

  int get totalSaved => _entries.fold(0, (sum, e) => sum + e.nominal);
  double get progress => _target > 0 ? (totalSaved / _target).clamp(0, 1) : 0;

  Future<void> _generateQr(int nominal) async {
    final qris = _merchantQrisCtl.text.trim();
    if (qris.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Set base QRIS merchant dulu")));
      return;
    }
    final name = _merchantNameCtl.text.isNotEmpty ? _merchantNameCtl.text : 'Tabungan';
    final city = _merchantCityCtl.text.isNotEmpty ? _merchantCityCtl.text : 'Indonesia';
    final withName = setMerchantName(qris, name);
    final withCity = setMerchantCity(withName, city);
    final gen = setAmount(withCity, nominal.toString());
    final qrImage = await QrRender.render(gen);
    if (!mounted) return;
    final timeoutMnt = int.tryParse(_timeoutCtl.text) ?? 15;
    final expiredAt = DateTime.now().add(Duration(minutes: timeoutMnt));
    final expiredStr = '${expiredAt.hour.toString().padLeft(2, '0')}:${expiredAt.minute.toString().padLeft(2, '0')}';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("QR Pembayaran"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(qrImage, width: 200, height: 200),
            const SizedBox(height: 12),
            Text("Rp ${_formatNominal(nominal)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Berlaku hingga $expiredStr", style: const TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            SelectableText(gen, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return Scaffold(appBar: AppBar(title: const Text("Tabungan")), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Tabungan")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressCard(progress: progress, totalSaved: totalSaved, target: _target, format: _formatNominal, theme: theme),
          const SizedBox(height: 12),
          _SectionCard(
            title: "Pengaturan Merchant",
            icon: Icons.store,
            expanded: _merchantExpanded,
            onToggle: () => setState(() => _merchantExpanded = !_merchantExpanded),
            child: Column(
              children: [
                _input("Base QRIS", _merchantQrisCtl, hint: "000201010211..."),
                const SizedBox(height: 10),
                _input("Nama Merchant", _merchantNameCtl, hint: "Toko Saya"),
                const SizedBox(height: 10),
                _input("Kota", _merchantCityCtl, hint: "Jakarta"),
                const SizedBox(height: 10),
                _input("Target Tabungan (Rp)", _targetCtl, hint: "1000000", keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                _input("Timeout QR (menit)", _timeoutCtl, hint: "15", keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveMerchant, child: const Text("Simpan Merchant"))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: "Catat Tabungan",
            icon: Icons.add_circle,
            expanded: true,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _input("Nominal (Rp)", _nominalCtl, hint: "50000", keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _selectedDate = d);
                      },
                      child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _input("Catatan (opsional)", _noteCtl, hint: "Gajian mingguan"),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _addEntry, child: const Text("Simpan Tabungan"))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("Belum ada catatan tabungan", style: TextStyle(color: Colors.white54))),
              ),
            )
          else
            _SectionCard(
              title: "Riwayat Tabungan (${_entries.length})",
              icon: Icons.history,
              expanded: true,
              child: Column(
                children: List.generate(_entries.length, (i) {
                  final e = _entries[i];
                  return Dismissible(
                    key: ValueKey('$i-${e.date.millisecondsSinceEpoch}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteEntry(i),
                    child: Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB84D).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.monetization_on, color: Color(0xFFFFB84D)),
                        ),
                        title: Text("Rp ${_formatNominal(e.nominal)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${e.dateStr} · ${e.note.isNotEmpty ? e.note : '-'}", style: const TextStyle(fontSize: 12, color: Colors.white54)),
                        trailing: IconButton(
                          icon: const Icon(Icons.qr_code, size: 20, color: Colors.white54),
                          onPressed: () => _generateQr(e.nominal),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: 12),
          _SectionCard(
            title: "Aksi",
            icon: Icons.more_horiz,
            expanded: true,
            child: Row(
              children: [
                Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.copy, size: 18), onPressed: _exportLogs, label: const Text("Export Log"))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.delete_forever, size: 18), onPressed: _clearAll, label: const Text("Hapus Semua"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700))),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _exportLogs() async {
    final entries = await SavingsService.getEntries();
    if (entries.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Belum ada data tabungan")));
      return;
    }
    final buf = StringBuffer();
    buf.writeln("=== TabuQR - Export Tabungan ===");
    buf.writeln("Total: Rp ${_formatNominal(totalSaved)}");
    if (_target > 0) buf.writeln("Target: Rp ${_formatNominal(_target)}");
    buf.writeln("---");
    for (final e in entries.reversed) {
      buf.writeln("${e.dateStr} | Rp ${_formatNominal(e.nominal)} | ${e.note.isNotEmpty ? e.note : '-'}");
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log disalin ke clipboard")));
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Hapus Semua Data?"),
        content: const Text("Semua catatan tabungan akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await SavingsService.clearAll();
    _entries.clear();
    setState(() {});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua data dihapus")));
  }

  Widget _input(String label, TextEditingController ctl, {String hint = '', TextInputType? keyboardType}) {
    return TextField(
      controller: ctl,
      decoration: InputDecoration(labelText: label, hintText: hint),
      keyboardType: keyboardType,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int totalSaved;
  final int target;
  final String Function(int) format;
  final ThemeData theme;

  const _ProgressCard({required this.progress, required this.totalSaved, required this.target, required this.format, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Progress Tabungan", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text("${(progress * 100).toStringAsFixed(1)}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFB84D))),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A6CF7)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Rp ${format(totalSaved)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(target > 0 ? "Target Rp ${format(target)}" : "Belum ada target", style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback? onToggle;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, this.expanded = true, this.onToggle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          if (onToggle != null)
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: const Color(0xFFFFB84D)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white54),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFFFFB84D)),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          if (expanded || onToggle == null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child),
        ],
      ),
    );
  }
}
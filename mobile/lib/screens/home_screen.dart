import 'package:flutter/material.dart';
import '../services/saved_qris_service.dart';
import '../qris/index.dart';
import 'qris_input_screen.dart';
import 'qris_detail_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SavedQris> _saved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _saved = await SavedQrisService.getAll();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    await SavedQrisService.delete(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TabuQR"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrisInputScreen())).then((_) => _load())),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_saved.isEmpty)
              _EmptyCard()
            else ...[
              Row(
                children: [
                  const Icon(Icons.bookmark, size: 18, color: Color(0xFFFFB84D)),
                  const SizedBox(width: 8),
                  Text("Tersimpan (${_saved.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              ..._saved.map((s) => _SavedQrisCard(saved: s, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => QrisDetailScreen(qrisString: s.qrisString))).then((_) => _load());
              }, onDelete: () => _delete(s.id))),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HeaderCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6CF7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_2, color: Color(0xFF4A6CF7), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("QRIS Tools", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Parse QRIS baru, generate pembayaran, atur webhook", style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bookmark_border, size: 40, color: Colors.white24),
              const SizedBox(height: 8),
              const Text("Belum ada QRIS tersimpan", style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 4),
              const Text("Parse QRIS baru lalu simpan untuk akses cepat", style: TextStyle(fontSize: 12, color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedQrisCard extends StatelessWidget {
  final SavedQris saved;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _SavedQrisCard({required this.saved, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6CF7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code, size: 22, color: Color(0xFF4A6CF7)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(saved.alias.isNotEmpty ? saved.alias : (saved.merchantName.isNotEmpty ? saved.merchantName : "QRIS ${saved.id.substring(0, 6)}"),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(saved.merchantName.isNotEmpty ? saved.merchantName : saved.qrisString.substring(0, 30),
                        style: TextStyle(fontSize: 12, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white38),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
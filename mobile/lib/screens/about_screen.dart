import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Tentang")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                children: [
                  Icon(Icons.account_balance_wallet, size: 48, color: theme.colorScheme.secondary),
                  const SizedBox(height: 12),
                  Text("TabuQR", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("v1.0.0", style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            ),
            const SizedBox(height: 20),
            _Section(title: "Apa itu TabuQR?",
              body: "Aplikasi multifungsi yang menggabungkan pengelolaan QRIS "
                  "(Quick Response Code Indonesian Standard) dengan pencatatan tabungan harian. "
                  "Cocok untuk merchant, UMKM, dan siapa pun yang ingin mengelola keuangan dengan QRIS."),
            const SizedBox(height: 16),
            _Section(title: "Fitur QRIS",
              body: "• Parse — melihat struktur TLV dari QRIS string\n"
                  "• Generate — membuat QR code dengan nominal custom",
            const SizedBox(height: 16),
            _Section(title: "Fitur Tabungan",
              body: "• Atur data merchant QRIS\n"
                  "• Tentukan target tabungan\n"
                  "• Catat pemasukan tabungan (nominal, tanggal, catatan)\n"
                  "• Lihat progress & log historis\n"
                  "• Data tersimpan aman di perangkat"),
            const SizedBox(height: 16),
            _Section(title: "Library",
              body: "Menggunakan @raoltech/qris (Node.js) — library QRIS modular "
                  "dengan 25+ fitur termasuk generate, parse, validasi, CRC16, dan TLV."),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
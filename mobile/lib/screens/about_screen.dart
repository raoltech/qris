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
              body: "Aplikasi QRIS multifungsi — parse, edit merchant, generate QR pembayaran dengan timeout, dan konfigurasi webhook. Dibangun dengan Flutter dan @raoltech/qris."),
            const SizedBox(height: 16),
            _Section(title: "Fitur",
              body: "• Parse — melihat struktur TLV dari QRIS string\n"
                  "• Generate — membuat QR pembayaran dengan nominal & timeout\n"
                  "• Ubah Merchant — edit nama & kota merchant\n"
                  "• Webhook — konfigurasi callback notifikasi\n"
                  "• Salin & Simpan — copy QRIS atau simpan sebagai JPG"),
            const SizedBox(height: 16),
            _Section(title: "Library",
              body: "Menggunakan @raoltech/qris — library QRIS modular dengan 25+ fitur termasuk generate, parse, validasi, CRC16, dan TLV."),
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
import 'package:flutter/material.dart';
import '../services/qris_tester.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  List<TestResult>? _results;
  bool _running = false;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _results = null;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    final r = await QrisTester.runAll();
    setState(() {
      _results = r;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pass = _results?.where((r) => r.pass).length ?? 0;
    final total = _results?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Full feature test (@raoltech/qris)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Menggunakan QRIS ID Dana asli.", style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _running ? null : _run,
            icon: const Icon(Icons.play_arrow),
            label: Text(_running ? "Running..." : "RUN ALL TESTS"),
          ),
          if (_results != null) ...[
            const SizedBox(height: 12),
            Text("TOTAL: $pass/$total PASS",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pass == total ? const Color(0xFF8BD16A) : Colors.orange)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _results!.length,
                itemBuilder: (_, i) {
                  final r = _results![i];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        r.pass ? Icons.check_circle : Icons.cancel,
                        color: r.pass ? const Color(0xFF8BD16A) : Colors.red,
                      ),
                      title: Text(r.name),
                      subtitle: r.extra != null ? Text(r.extra!) : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

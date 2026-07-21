import 'package:flutter/material.dart';
import '../qris/index.dart';

class ParseScreen extends StatefulWidget {
  const ParseScreen({super.key});

  @override
  State<ParseScreen> createState() => _ParseScreenState();
}

class _ParseScreenState extends State<ParseScreen> {
  final _ctrl = TextEditingController();
  ParsedQRIS? _parsed;
  ValidationResult? _valid;
  String? _error;

  void _parse() {
    try {
      final p = parseQRIS(_ctrl.text.trim());
      final v = validateQRIS(_ctrl.text.trim());
      setState(() {
        _parsed = p;
        _valid = v;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              labelText: "QRIS String",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _parse,
            icon: const Icon(Icons.visibility),
            label: const Text("PARSE"),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text("Error: $_error", style: const TextStyle(color: Colors.red)),
          ],
          if (_valid != null) ...[
            const SizedBox(height: 12),
            Chip(
              label: Text(_valid!.valid ? "VALID" : "INVALID"),
              backgroundColor:
                  _valid!.valid ? const Color(0xFF5BA13A) : Colors.red,
              labelStyle: const TextStyle(color: Colors.white),
            ),
            if (_valid!.error != null)
              Text("Note: ${_valid!.error}", style: const TextStyle(color: Colors.orange)),
            const SizedBox(height: 10),
            if (_parsed != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_parsed!.pretty(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF8BD16A))),
              ),
          ],
        ],
      ),
    );
  }
}

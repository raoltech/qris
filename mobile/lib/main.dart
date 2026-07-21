import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/generator_screen.dart';
import 'screens/parse_screen.dart';
import 'screens/tabungan_screen.dart';
import 'screens/about_screen.dart';

void main() => runApp(const QrisApp());

class QrisApp extends StatelessWidget {
  const QrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TabuQR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4A6CF7),
          secondary: Color(0xFFFFB84D),
          surface: Color(0xFF1E293B),
          background: Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: CardTheme(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A6CF7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          labelStyle: const TextStyle(color: Colors.white60),
        ),
      ),
      routes: {
        '/': (_) => const HomeScreen(),
        '/qr-menu': (_) => const QrMenuScreen(),
        '/tabungan': (_) => const TabunganScreen(),
        '/about': (_) => const AboutScreen(),
      },
    );
  }
}

class QrMenuScreen extends StatefulWidget {
  const QrMenuScreen({super.key});

  @override
  State<QrMenuScreen> createState() => _QrMenuScreenState();
}

class _QrMenuScreenState extends State<QrMenuScreen> {
  int _idx = 0;
  final _pages = const [GeneratorScreen(), ParseScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fitur QRIS")),
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: const Color(0xFFFFB84D),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: "Generator"),
          BottomNavigationBarItem(icon: Icon(Icons.visibility), label: "Parse"),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/qris_input_screen.dart';
import 'screens/qris_detail_screen.dart';
import 'screens/about_screen.dart';

void main() => runApp(const TabuqrApp());

class TabuqrApp extends StatelessWidget {
  const TabuqrApp({super.key});

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
        '/input': (_) => const QrisInputScreen(),
        '/about': (_) => const AboutScreen(),
      },
    );
  }
}

class QrisDetailRoute extends StatelessWidget {
  final String qrisString;
  const QrisDetailRoute(this.qrisString, {super.key});

  @override
  Widget build(BuildContext context) => QrisDetailScreen(qrisString: qrisString);
}
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menus = [
      _MenuItem(
        icon: Icons.qr_code_2,
        label: "Fitur QRIS",
        desc: "Parse, generate & test QRIS",
        route: '/qr-menu',
        color: const Color(0xFF4A6CF7),
      ),
      _MenuItem(
        icon: Icons.account_balance_wallet,
        label: "Tabungan",
        desc: "Atur target, catat & lacak tabungan",
        route: '/tabungan',
        color: const Color(0xFFFFB84D),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        label: "Tentang",
        desc: "Penjelasan tentang aplikasi ini",
        route: '/about',
        color: const Color(0xFFA78BFA),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("TabuQR"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text("Menu", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: menus.length,
                itemBuilder: (_, i) => _MenuCard(menu: menus[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String desc;
  final String route;
  final Color color;
  const _MenuItem({required this.icon, required this.label, required this.desc, required this.route, required this.color});
}

class _MenuCard extends StatelessWidget {
  final _MenuItem menu;
  const _MenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, menu.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: menu.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(menu.icon, color: menu.color, size: 28),
              ),
              const Spacer(),
              Text(menu.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(menu.desc, style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../core/auth/auth_service.dart';
import 'profit_loss_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void go(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole ?? "unknown";

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Welcome, $role",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          _card("Inventory", Icons.inventory,
              () => go(context, "/inventory")),
          _card("Sales", Icons.point_of_sale, () => go(context, "/sales")),
          _card("Users", Icons.people, () => go(context, "/users")),

          const SizedBox(height: 10),

          // ✅ FIXED: REAL SCREEN
          _card("Profit & Loss", Icons.bar_chart, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfitLossScreen(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _card(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Icon(icon),
        onTap: onTap,
      ),
    );
  }
}
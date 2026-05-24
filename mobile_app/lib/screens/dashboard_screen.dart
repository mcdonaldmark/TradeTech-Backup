import 'package:flutter/material.dart';
import '../core/auth/auth_service.dart';
import 'login_screen.dart';
import 'profit_loss_screen.dart';
import 'order_history_screen.dart';
import 'create_order_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void go(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  Future<void> logout(BuildContext context) async {
    await AuthService.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole ?? "unknown";

    final isCashier = role == "cashier";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Welcome, $role",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _card(
            title: "Inventory",
            icon: Icons.inventory,
            onTap: () => go(context, "/inventory"),
          ),

          const SizedBox(height: 12),

          if (!isCashier) ...[
            _card(
              title: "Sales",
              icon: Icons.point_of_sale,
              onTap: () => go(context, "/sales"),
            ),
            const SizedBox(height: 12),
          ],

          _card(
            title: "Users",
            icon: Icons.people,
            onTap: () => go(context, "/users"),
          ),

          const SizedBox(height: 12),

          if (isCashier) ...[
            _card(
              title: "Create Order",
              icon: Icons.add_shopping_cart,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateOrderScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _card(
              title: "Order History",
              icon: Icons.receipt_long,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
          ],

          if (!isCashier)
            _card(
              title: "Profit & Loss",
              icon: Icons.bar_chart,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfitLossScreen(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 70,
      child: Card(
        elevation: 3,
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Icon(
            icon,
            size: 28,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
          onTap: onTap,
        ),
      ),
    );
  }
}
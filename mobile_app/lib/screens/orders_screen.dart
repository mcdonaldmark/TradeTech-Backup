import 'package:flutter/material.dart';
import 'create_order_screen.dart';
import 'order_history_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget card(String title, IconData icon, VoidCallback onTap) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Icon(icon),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          card(
            "Create Order",
            Icons.add_shopping_cart,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateOrderScreen(),
                ),
              );
            },
          ),
          card(
            "Order History",
            Icons.history,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
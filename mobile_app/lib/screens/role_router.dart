import 'package:flutter/material.dart';
import '../core/auth/auth_service.dart';
import 'inventory_screen.dart';
import 'dashboard_screen.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole;

    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (role == "user") {
      return const InventoryScreen(); // user = products only
    }

    if (role == "cashier") {
      return const InventoryScreen(); // cashier sees inventory + sales (handled inside screens)
    }

    if (role == "manager" || role == "director") {
      return const DashboardScreen();
    }

    return const InventoryScreen();
  }
}
import 'package:flutter/material.dart';
import '../core/auth/auth_service.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'user_home_screen.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole;

    print("ROLE ROUTER: $role");

    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (role == "user") {
      return const UserHomeScreen();
    }

    if (role == "cashier") {
      return const DashboardScreen();
    }

    if (role == "manager" || role == "director") {
      return const DashboardScreen();
    }

    return const Scaffold(
      body: Center(child: Text("Invalid role")),
    );
  }
}
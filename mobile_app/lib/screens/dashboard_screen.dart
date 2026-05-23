import 'package:flutter/material.dart';
import '../widgets/role_guard.dart';
import '../core/auth/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole ?? "unknown";

    return RoleGuard(
      userRole: role,
      allowedRoles: const ["user", "cashier", "manager", "director"],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Dashboard"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, $role",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Card(
                child: ListTile(
                  title: const Text("Inventory"),
                  trailing: const Icon(Icons.inventory),
                  onTap: () => Navigator.pushNamed(context, "/inventory"),
                ),
              ),

              Card(
                child: ListTile(
                  title: const Text("Sales"),
                  trailing: const Icon(Icons.point_of_sale),
                  onTap: () => Navigator.pushNamed(context, "/sales"),
                ),
              ),

              Card(
                child: ListTile(
                  title: const Text("Users"),
                  trailing: const Icon(Icons.people),
                  onTap: () => Navigator.pushNamed(context, "/users"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
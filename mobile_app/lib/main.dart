import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/users_screen.dart';
import 'screens/profit_loss_screen.dart';

void main() {
  runApp(const TradeTechApp());
}

class TradeTechApp extends StatelessWidget {
  const TradeTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TradeTech',
      theme: ThemeData(primarySwatch: Colors.blue),

      // START HERE
      home: const LoginScreen(),

      routes: {
        "/dashboard": (_) => const DashboardScreen(),
        "/inventory": (_) => const InventoryScreen(),
        "/sales": (_) => const SalesScreen(),
        "/users": (_) => const UsersScreen(),
        "/profit-loss": (_) => const ProfitLossScreen(),
      },
    );
  }
}
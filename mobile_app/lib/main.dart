import 'package:flutter/material.dart';
import 'core/auth/auth_service.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/users_screen.dart';
import 'screens/profit_loss_screen.dart';
import 'screens/orders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load saved token + user session BEFORE app starts
  await AuthService.loadSession();

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

      // 🔥 IMPORTANT CHANGE:
      // We no longer hardcode LoginScreen as the entry point
      // We let RoleRouter decide OR fallback logic handle auth state
      home: const LoginScreen(),

      routes: {
        "/dashboard": (_) => const DashboardScreen(),
        "/inventory": (_) => const InventoryScreen(),
        "/sales": (_) => const SalesScreen(),
        "/users": (_) => const UsersScreen(),
        "/profit-loss": (_) => const ProfitLossScreen(),
        "/orders": (_) => const OrdersScreen(),
      },
    );
  }
}
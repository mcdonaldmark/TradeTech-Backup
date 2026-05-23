import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

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
      home: const LoginScreen(),
    );
  }
}
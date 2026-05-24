import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/storage/token_storage.dart';
import 'order_receipt_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final String baseUrl = "http://192.168.68.114:5000/api";

  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final token = await TokenStorage.getToken(); // ✅ FIX

      final res = await http.get(
        Uri.parse("$baseUrl/orders"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        setState(() {
          // backend always returns a LIST
          orders = decoded is List ? decoded : [];
          loading = false;
        });
      } else {
        setState(() {
          orders = [];
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        orders = [];
        loading = false;
      });
    }
  }

  void openReceipt(orderId) async {
  try {
    final token = await TokenStorage.getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/orders/$orderId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load receipt")),
      );
      return;
    }

    final decoded = jsonDecode(res.body);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderReceiptScreen(order: decoded),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Text(
                    "No orders found",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final o = orders[i];

                    return Card(
                      child: ListTile(
                        title: Text("Order #${o['id']}"),
                        subtitle: Text(
                          "Total: \$${o['total']} • Status: ${o['status'] ?? 'pending'}",
                        ),
                        trailing: const Icon(Icons.receipt_long),
                        onTap: () => openReceipt(o['id']),
                      ),
                    );
                  },
                ),
    );
  }
}
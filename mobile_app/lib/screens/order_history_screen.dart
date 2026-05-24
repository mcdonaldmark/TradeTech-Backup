import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/storage/token_storage.dart';
import '../core/auth/auth_service.dart';
import 'order_receipt_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final String baseUrl = "http://192.168.68.114:5000/api";

  List orders = [];
  bool loading = false;

  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      setState(() => loading = true);

      final token = await TokenStorage.getToken();
      final role = AuthService.currentRole;

      String endpoint;

      if (role == "user") {
        endpoint = "$baseUrl/orders/my";
      } else {
        final query = searchQuery.trim();

        if (query.isEmpty) {
          setState(() {
            orders = [];
            loading = false;
          });
          return;
        }

        endpoint = "$baseUrl/orders?search=$query";
      }

      final res = await http.get(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        setState(() {
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
          const SnackBar(content: Text("Failed to load receipt")),
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

  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);

      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
             "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole;

    return Scaffold(
      appBar: AppBar(title: const Text("Order History")),

      body: Column(
        children: [

          if (role != "user")
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: "Search by User Name or ID",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        searchQuery = searchController.text.trim();
                      });
                      fetchOrders();
                    },
                    child: const Text("Search Orders"),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          if (role != "user" && searchQuery.isEmpty)
            const Expanded(
              child: Center(
                child: Text("Search a user to view order history"),
              ),
            )
          else if (loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (orders.isEmpty)
            const Expanded(
              child: Center(child: Text("No orders found")),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (_, i) {
                  final o = orders[i];

                  return Card(
                    child: ListTile(
                      title: Text("Order #${o['id']}"),
                      subtitle: Text(
                        "User: ${o['user_name'] ?? 'Unknown'}\n"
                        "Total: \$${o['total']} • Status: ${o['status'] ?? 'pending'}\n"
                        "Date: ${_formatDate(o['created_at'])}",
                      ),
                      trailing: const Icon(Icons.receipt_long),
                      onTap: () => openReceipt(o['id']),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
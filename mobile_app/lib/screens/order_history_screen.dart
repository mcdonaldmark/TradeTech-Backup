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
  // ✅ RENDER BACKEND
  final String baseUrl = "https://tradetech-api-ksas.onrender.com/api";

  List orders = [];
  List users = [];

  bool loading = true;

  final TextEditingController searchController = TextEditingController();

  List filteredUsers = [];
  int? selectedUserId;
  String? selectedUserName;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchOrders();
  }

  // ================= USERS (FOR DROPDOWN SEARCH) =================
  Future<void> fetchUsers() async {
    try {
      final token = await TokenStorage.getToken();

      final res = await http.get(
        Uri.parse("$baseUrl/users"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(res.body);

      setState(() {
        users = data is List ? data : (data["data"] ?? []);
      });
    } catch (_) {}
  }

  // ================= ORDERS =================
  Future<void> fetchOrders({int? userId}) async {
    setState(() => loading = true);

    try {
      final token = await TokenStorage.getToken();
      final role = AuthService.currentRole;

      String endpoint;

      // USER sees only their orders
      if (role == "user") {
        endpoint = "$baseUrl/orders/my";
      } else {
        // cashier/manager: filter by selected user OR load all
        endpoint = userId != null
            ? "$baseUrl/orders?user_id=$userId"
            : "$baseUrl/orders";
      }

      final res = await http.get(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final decoded = jsonDecode(res.body);

      setState(() {
        orders = decoded is List
            ? decoded
            : (decoded["data"] ?? decoded["orders"] ?? []);
        loading = false;
      });
    } catch (e) {
      setState(() {
        orders = [];
        loading = false;
      });
    }
  }

  // ================= USER SEARCH DROPDOWN =================
  void searchUser(String query) {
    final role = AuthService.currentRole;
    if (role == "user") return;

    if (query.trim().isEmpty) {
      setState(() => filteredUsers = []);
      return;
    }

    setState(() {
      filteredUsers = users.where((u) {
        final idMatch = u['id'].toString().contains(query);
        final nameMatch =
            u['name'].toString().toLowerCase().contains(query.toLowerCase());

        return idMatch || nameMatch;
      }).toList();
    });
  }

  void selectUser(dynamic user) {
    setState(() {
      selectedUserId = user['id'];
      selectedUserName = user['name'];

      searchController.text = "${user['name']} (#${user['id']})";
      filteredUsers.clear();

      fetchOrders(userId: user['id']);
    });
  }

  // ================= RECEIPT =================
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

      if (res.statusCode != 200) return;

      final decoded = jsonDecode(res.body);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderReceiptScreen(order: decoded),
        ),
      );
    } catch (_) {}
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
          "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole;

    return Scaffold(
      appBar: AppBar(title: const Text("Order History")),

      body: Column(
        children: [

          // ================= SEARCH DROPDOWN =================
          if (role != "user")
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: "Search User (Name or ID)",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: searchUser,
                  ),

                  if (filteredUsers.isNotEmpty)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(top: 8),
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (_, i) {
                          final u = filteredUsers[i];

                          return ListTile(
                            title: Text(u['name']),
                            subtitle: Text("ID: ${u['id']}"),
                            onTap: () => selectUser(u),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ================= STATES =================
          if (loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (orders.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  selectedUserId == null
                      ? "Search a user to view orders"
                      : "No orders for this user",
                ),
              ),
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
                        "User: ${o['user_name'] ?? o['user'] ?? 'Unknown'}\n"
                        "Total: \$${o['total']} • ${o['status'] ?? 'pending'}\n"
                        "Date: ${_formatDate(o['created_at'] ?? '')}",
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
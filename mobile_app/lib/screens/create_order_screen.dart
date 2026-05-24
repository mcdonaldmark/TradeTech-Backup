import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/storage/token_storage.dart';
import '../core/auth/auth_service.dart';
import '../models/order_item.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final String baseUrl = "http://192.168.68.114:5000/api";

  List users = [];
  List products = [];
  List<OrderItem> cart = [];

  int? selectedUserId;
  String? selectedUserName;

  final TextEditingController userSearchController = TextEditingController();
  List filteredUsers = [];

  @override
  void initState() {
    super.initState();
    loadData();

    final role = AuthService.currentRole;

    if (role == "user") {
      selectedUserId = AuthService.currentUserId;
      _loadCurrentUserName(); // 🔥 NEW
    }
  }

  Future<void> _loadCurrentUserName() async {
    try {
      final token = await TokenStorage.getToken();

      final res = await http.get(
        Uri.parse("$baseUrl/users"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final allUsers = jsonDecode(res.body);

      final current = allUsers.firstWhere(
        (u) => u['id'] == AuthService.currentUserId,
        orElse: () => null,
      );

      if (current != null) {
        setState(() {
          selectedUserName = current['name']; // ✅ REAL NAME
        });
      } else {
        setState(() {
          selectedUserName = "Unknown User";
        });
      }
    } catch (e) {
      setState(() {
        selectedUserName = "Unknown User";
      });
    }
  }

  Future<void> loadData() async {
    final token = await TokenStorage.getToken();

    final u = await http.get(
      Uri.parse("$baseUrl/users"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final p = await http.get(
      Uri.parse("$baseUrl/inventory"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    setState(() {
      users = jsonDecode(u.body);
      products = jsonDecode(p.body);
    });
  }

  void searchUser(String query) {
    final role = AuthService.currentRole;

    if (role == "user") return;

    if (query.trim().isEmpty) {
      setState(() => filteredUsers = []);
      return;
    }

    final results = users.where((u) {
      final idMatch = u['id'].toString().contains(query.trim());
      final nameMatch =
          u['name'].toString().toLowerCase().contains(query.toLowerCase());

      return idMatch || nameMatch;
    }).toList();

    setState(() {
      filteredUsers = results;
    });
  }

  void selectUser(dynamic user) {
    final role = AuthService.currentRole;

    if (role == "user") return;

    setState(() {
      selectedUserId = user['id'];
      selectedUserName = user['name'];

      userSearchController.text = "${user['name']} (#${user['id']})";
      filteredUsers.clear();
    });
  }

  void addToCart(product) {
    final index =
        cart.indexWhere((e) => e.productId == product['id']);

    if (index >= 0) {
      setState(() => cart[index].quantity++);
    } else {
      setState(() {
        cart.add(OrderItem(
          productId: product['id'],
          name: product['name'],
          price: double.parse(product['price'].toString()),
        ));
      });
    }
  }

  double get total =>
      cart.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> submitOrder() async {
    final token = await TokenStorage.getToken();

    final userId = selectedUserId ?? AuthService.currentUserId;

    final body = {
      "user_id": userId,
      "items": cart
          .map((e) => {
                "product_id": e.productId,
                "quantity": e.quantity,
              })
          .toList()
    };

    final res = await http.post(
      Uri.parse("$baseUrl/orders"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 201) {
      setState(() {
        cart.clear();

        if (AuthService.currentRole != "user") {
          selectedUserId = null;
          selectedUserName = null;
          userSearchController.clear();
          filteredUsers.clear();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order created successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.body)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole;
    final isUser = role == "user";

    return Scaffold(
      appBar: AppBar(title: const Text("Create Order")),
      body: Column(
        children: [

          if (isUser)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(selectedUserName ?? "Loading..."),
                  subtitle: Text(
                    "User ID: ${selectedUserId ?? ''}",
                  ),
                ),
              ),
            ),

          if (!isUser)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: userSearchController,
                    decoration: const InputDecoration(
                      labelText: "Search User (ID or Name)",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: searchUser,
                  ),

                  if (filteredUsers.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredUsers.length,
                        itemBuilder: (_, i) {
                          final user = filteredUsers[i];

                          return ListTile(
                            title: Text(user['name']),
                            subtitle: Text("ID: ${user['id']}"),
                            onTap: () => selectUser(user),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          const Divider(),

          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];

                return ListTile(
                  title: Text(p['name']),
                  subtitle: Text("\$${p['price']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => addToCart(p),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  "Total: \$${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty ? null : submitOrder,
                    child: const Text("Submit Order"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
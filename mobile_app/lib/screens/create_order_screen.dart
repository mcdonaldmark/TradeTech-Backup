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

  final TextEditingController userSearchController =
      TextEditingController();

  List filteredUsers = [];

  @override
  void initState() {
    super.initState();
    loadData();
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

  // ================= USER SEARCH =================

  void searchUser(String query) {
    if (query.trim().isEmpty) {
      setState(() => filteredUsers = []);
      return;
    }

    final results = users.where((u) {
      final idMatch =
          u['id'].toString().contains(query.trim());

      final nameMatch = u['name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());

      return idMatch || nameMatch;
    }).toList();

    setState(() {
      filteredUsers = results;
    });
  }

  void selectUser(dynamic user) {
    setState(() {
      selectedUserId = user['id'];
      selectedUserName = user['name'];

      userSearchController.text =
          "${user['name']} (#${user['id']})";

      filteredUsers.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Selected: ${user['name']}")),
    );
  }

  // ================= CART =================

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

  // ================= SUBMIT ORDER =================

  Future<void> submitOrder() async {
    final token = await TokenStorage.getToken();

    final body = {
      "user_id": selectedUserId,
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
        selectedUserId = null;
        selectedUserName = null;
        userSearchController.clear();
        filteredUsers.clear();
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

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Order")),

      body: Column(
        children: [
          // ================= USER SEARCH =================
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
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
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

          if (selectedUserId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: Text(selectedUserName ?? ""),
                  subtitle: Text("User ID: $selectedUserId"),
                ),
              ),
            ),

          const Divider(),

          // ================= PRODUCTS =================
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

          // ================= CART =================
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
                    onPressed: cart.isEmpty || selectedUserId == null
                        ? null
                        : submitOrder,
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
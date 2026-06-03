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
  final TextEditingController productSearchController = TextEditingController();

  String productQuery = "";
  List filteredUsers = [];

  @override
  void initState() {
    super.initState();
    loadData();

    final role = AuthService.currentRole;

    if (role == "user") {
      selectedUserId = AuthService.currentUserId;
      _loadCurrentUserName();
    }
  }

  // ================= SAFE DECODER (FIX FOR INVENTORY ISSUE) =================
  List safeDecode(String body) {
    final decoded = jsonDecode(body);

    if (decoded is List) return decoded;

    if (decoded is Map) {
      if (decoded["data"] is List) return decoded["data"];
      if (decoded["inventory"] is List) return decoded["inventory"];
      if (decoded["products"] is List) return decoded["products"];
    }

    return [];
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

      final allUsers = safeDecode(res.body);

      final current = allUsers.firstWhere(
        (u) => u['id'] == AuthService.currentUserId,
        orElse: () => null,
      );

      setState(() {
        selectedUserName =
            current != null ? current['name'] : "Unknown User";
      });
    } catch (_) {
      setState(() {
        selectedUserName = "Unknown User";
      });
    }
  }

  // ================= LOAD USERS + INVENTORY =================
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
      users = safeDecode(u.body);
      products = safeDecode(p.body);
    });
  }

  // ================= USER SEARCH =================
  void searchUser(String query) {
    final role = AuthService.currentRole;
    if (role == "user") return;

    if (query.trim().isEmpty) {
      setState(() => filteredUsers = []);
      return;
    }

    setState(() {
      filteredUsers = users.where((u) {
        final idMatch = u['id'].toString().contains(query.trim());
        final nameMatch =
            u['name'].toString().toLowerCase().contains(query.toLowerCase());

        return idMatch || nameMatch;
      }).toList();
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

  // ================= PRODUCT SEARCH =================
  void searchProducts(String query) {
    setState(() {
      productQuery = query;
    });
  }

  List get filteredProducts {
    final list = products.where((p) => p is Map).toList();

    if (productQuery.trim().isEmpty) return list;

    return list.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(productQuery.toLowerCase());
    }).toList();
  }

  void addToCart(product) {
    final index = cart.indexWhere((e) => e.productId == product['id']);

    setState(() {
      if (index >= 0) {
        cart[index].quantity++;
      } else {
        cart.add(OrderItem(
          productId: product['id'],
          name: product['name'],
          price: double.parse(product['price'].toString()),
        ));
      }
    });
  }

  double get total => cart.fold(0, (sum, item) => sum + item.subtotal);

  String _imageOf(dynamic p) {
    final img = p['image_url'];
    if (img == null || img.toString().isEmpty) return "";
    return img.toString();
  }

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
        filteredUsers.clear();
        userSearchController.clear();
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
    final isUser = AuthService.currentRole == "user";

    return Scaffold(
      appBar: AppBar(title: const Text("Create Order")),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            children: [

              const SizedBox(height: 10),

              // ================= USER SEARCH =================
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: userSearchController,
                        decoration: const InputDecoration(
                          labelText: "Search User",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: searchUser,
                      ),

                      if (filteredUsers.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
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

              // ================= PRODUCT SEARCH =================
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: productSearchController,
                  decoration: const InputDecoration(
                    labelText: "Search Products",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: searchProducts,
                ),
              ),

              // ================= PRODUCTS =================
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                itemBuilder: (_, i) {
                  final p = filteredProducts[i];

                  final img = _imageOf(p);

                  return ListTile(
                    leading: img.isNotEmpty
                        ? Image.memory(
                            base64Decode(img),
                            width: 45,
                            height: 45,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image),

                    title: Text(p['name']),
                    subtitle: Text("\$${p['price']}"),

                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => addToCart(p),
                    ),
                  );
                },
              ),

              const Divider(),

              // ================= TOTAL =================
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
        ),
      ),
    );
  }
}
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

      setState(() {
        selectedUserName = current != null ? current['name'] : "Unknown User";
      });
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

    setState(() {
      filteredUsers = users.where((u) {
        final idMatch = u['id'].toString().contains(query.trim());
        final nameMatch =
            u['name'].toString().toLowerCase().contains(query.toLowerCase());

        return idMatch || nameMatch;
      }).toList();
    });
  }

  void searchProducts(String query) {
    setState(() {
      productQuery = query;
    });
  }

  List get filteredProducts {
    if (productQuery.trim().isEmpty) return products;

    return products.where((p) {
      final name = p['name'].toString().toLowerCase();
      return name.contains(productQuery.toLowerCase());
    }).toList();
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
    final role = AuthService.currentRole;
    final isUser = role == "user";

    return Scaffold(
      appBar: AppBar(title: const Text("Create Order")),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // USER SECTION
              if (isUser)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(selectedUserName ?? "Loading..."),
                      subtitle: Text("User ID: ${selectedUserId ?? ''}"),
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

              const Divider(),

              // PRODUCT SEARCH
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

              // PRODUCT LIST (SAFE)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                itemBuilder: (_, i) {
                  final p = filteredProducts[i];

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

              const Divider(),

              // TOTAL + BUTTON
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
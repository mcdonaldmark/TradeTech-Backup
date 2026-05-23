import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> products = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService.get("inventory");

      final List data = res as List;

      setState(() {
        products = data.map((item) => Product.fromJson(item)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory")),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(child: Text("Error: $error")),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: fetchProducts,
                          child: const Text("Retry"),
                        ),
                      )
                    ],
                  )
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];

                      return Card(
                        child: ListTile(
                          title: Text(p.name),
                          subtitle: Text(
                            "Qty: ${p.quantity} | \$${p.price}",
                          ),
                          trailing: const Icon(Icons.edit),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
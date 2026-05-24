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
      final List data = res;

      setState(() {
        products = data.map((e) => Product.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> createProduct(Map data) async {
    try {
      await ApiService.post("inventory", data);
      fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> updateProduct(int id, Map data) async {
    try {
      await ApiService.put("inventory/$id", data);
      fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await ApiService.delete("inventory/$id");

      setState(() {
        products.removeWhere((p) => p.id == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void showProductDialog({Product? product}) {
    final nameController =
        TextEditingController(text: product?.name ?? "");
    final descController =
        TextEditingController(text: product?.description ?? "");
    final qtyController =
        TextEditingController(text: product?.quantity.toString() ?? "");
    final priceController =
        TextEditingController(text: product?.price.toString() ?? "");

    final imageController =
        TextEditingController(text: product?.imageUrl ?? "");
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product == null ? "Add Product" : "Edit Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "Image URL"),
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: "Cost Price"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final data = {
                "name": nameController.text,
                "description": descController.text,
                "quantity": int.tryParse(qtyController.text) ?? 0,
                "price": double.tryParse(priceController.text) ?? 0,
                "image_url": imageController.text,
                "cost_price": double.tryParse(costController.text) ?? 0,
              };

              Navigator.pop(context);

              if (product == null) {
                createProduct(data);
              } else {
                updateProduct(product.id, data);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory")),

      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductDialog(),
        child: const Icon(Icons.add),
      ),

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
                          leading: (p.imageUrl != null &&
                                  p.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  p.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image);
                                  },
                                )
                              : const Icon(Icons.image),

                          title: Text(p.name),
                          subtitle: Text(
                            "Qty: ${p.quantity} | \$${p.price}",
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    showProductDialog(product: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => deleteProduct(p.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
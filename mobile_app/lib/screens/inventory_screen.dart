import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api/api_service.dart';
import '../core/auth/auth_service.dart';
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

  bool get isCashier => AuthService.currentRole == "cashier";

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
    await ApiService.post("inventory", data);
    fetchProducts();
  }

  Future<void> updateProduct(int id, Map data) async {
    await ApiService.put("inventory/$id", data);
    fetchProducts();
  }

  Future<void> deleteProduct(int id) async {
    await ApiService.delete("inventory/$id");
    fetchProducts();
  }

  Future<String?> pickImageBase64() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Widget buildImage(String? img) {
    if (img == null || img.isEmpty) {
      return const Icon(Icons.image, size: 40);
    }

    try {
      return Image.memory(
        base64Decode(img),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return const Icon(Icons.broken_image, size: 40);
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

    // ✅ NEW: cost price controller
    final costController =
        TextEditingController(text: product?.costPrice?.toString() ?? "");

    String? imageBase64 = product?.imageUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(product == null ? "Add Product" : "Edit Product"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: "Product Name"),
                  ),
                  TextField(
                    controller: descController,
                    decoration:
                        const InputDecoration(labelText: "Description"),
                  ),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: "Quantity"),
                  ),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: "Price"),
                  ),

                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: "Cost Price"),
                  ),

                  const SizedBox(height: 10),

                  imageBase64 != null && imageBase64!.isNotEmpty
                      ? Image.memory(
                          base64Decode(imageBase64!),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 80),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final img = await pickImageBase64();

                      if (img != null && img.isNotEmpty) {
                        setModalState(() {
                          imageBase64 = img;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo),
                    label: const Text("Pick Image"),
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

                    // ✅ NEW BACKEND FIELD
                    "cost_price":
                        double.tryParse(costController.text) ?? 0,

                    "image_url": imageBase64 ?? "",
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory")),

      floatingActionButton: isCashier
          ? null
          : FloatingActionButton(
              onPressed: () => showProductDialog(),
              child: const Icon(Icons.add),
            ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text("Error: $error"))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];

                    return Card(
                      child: ListTile(
                        leading: buildImage(p.imageUrl),

                        title: Text(p.name),

                        subtitle: Text(
                          "Qty: ${p.quantity} | \$${p.price}"
                          "${p.costPrice != null ? " | Cost: \$${p.costPrice}" : ""}",
                        ),

                        trailing: isCashier
                            ? null
                            : Row(
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
    );
  }
}
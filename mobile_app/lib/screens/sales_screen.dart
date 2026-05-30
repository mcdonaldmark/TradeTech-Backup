import 'package:flutter/material.dart';
import 'dart:convert';

import '../core/api/api_service.dart';
import '../models/sale.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> sales = [];
  List inventory = [];

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchSales();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      final res = await ApiService.get("inventory");
      setState(() {
        inventory = (res is List) ? res : [];
      });
    } catch (_) {}
  }

  Future<void> fetchSales() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService.get("sales");

      final List data = (res is List)
          ? res
          : (res is Map && res["data"] is List)
              ? res["data"]
              : [];

      setState(() {
        sales = data.map((e) => Sale.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> deleteSale(int id) async {
    try {
      await ApiService.delete("sales/$id");
      fetchSales();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  String resolveImage(Sale sale) {
    try {
      final match = inventory.firstWhere(
        (p) => p["name"] == sale.productName,
        orElse: () => null,
      );

      final img = match?["image_url"];

      if (img == null || img.toString().isEmpty) return "";

      final value = img.toString();

      if (value.startsWith("/") ||
          value.contains("cache") ||
          value.contains(".jpg") ||
          value.contains(".png")) {
        return "";
      }

      return value;
    } catch (_) {
      return "";
    }
  }

  Widget buildImage(String img) {
    try {
      return Image.memory(
        base64Decode(img),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return const Icon(Icons.image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales")),

      body: RefreshIndicator(
        onRefresh: fetchSales,
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
                          onPressed: fetchSales,
                          child: const Text("Retry"),
                        ),
                      )
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Builder(
                          builder: (_) {
                            final totalRevenue = sales.fold<double>(
                                0, (sum, s) => sum + s.totalRevenue);

                            final totalProfit = sales.fold<double>(
                                0, (sum, s) => sum + s.profit);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Sales Summary",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    "Revenue: \$${totalRevenue.toStringAsFixed(2)}"),
                                Text(
                                  "Profit: \$${totalProfit.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: totalProfit >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      Expanded(
                        child: ListView.builder(
                          itemCount: sales.length,
                          itemBuilder: (context, index) {
                            final s = sales[index];
                            final img = resolveImage(s);

                            return Card(
                              child: ListTile(
                                leading: img.isNotEmpty
                                    ? buildImage(img)
                                    : const Icon(Icons.image),

                                title: Text(s.productName),
                                subtitle: Text(
                                    "Qty: ${s.quantitySold} | \$${s.totalRevenue.toStringAsFixed(2)}"),

                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "\$${s.profit.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: s.profit >= 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => deleteSale(s.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
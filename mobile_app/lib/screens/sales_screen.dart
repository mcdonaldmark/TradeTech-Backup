import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../models/sale.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> sales = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchSales();
  }

  Future<void> fetchSales() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService.get("sales");
      final List data = res;

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

  Future<void> createSale(Map data) async {
    try {
      await ApiService.post("sales", data);
      fetchSales();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ✅ NEW: DELETE SALE
  Future<void> deleteSale(int id) async {
    try {
      await ApiService.delete("sales/$id");
      fetchSales(); // refresh so totals update correctly
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  void showSaleDialog() {
    final productController = TextEditingController();
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create Sale"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productController,
              decoration:
                  const InputDecoration(labelText: "Product Name or ID"),
            ),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final productInput = productController.text.trim();
              final qty = int.tryParse(qtyController.text) ?? 0;

              Navigator.pop(context);

              createSale({
                if (int.tryParse(productInput) != null)
                  "product_id": int.parse(productInput)
                else
                  "product_name": productInput,
                "quantity_sold": qty,
              });
            },
            child: const Text("Sell"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales")),
      floatingActionButton: FloatingActionButton(
        onPressed: showSaleDialog,
        child: const Icon(Icons.add),
      ),
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
                      // SUMMARY
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Builder(
                          builder: (_) {
                            final totalRevenue =
                                sales.fold<double>(0, (sum, s) => sum + s.totalRevenue);

                            final totalProfit =
                                sales.fold<double>(0, (sum, s) => sum + s.profit);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Sales Summary",
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    "Total Revenue: \$${totalRevenue.toStringAsFixed(2)}"),
                                Text(
                                  "Total Profit: \$${totalProfit.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: totalProfit >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
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

                            return Card(
                              child: ListTile(
                                title: Text(s.productName),
                                subtitle: Text(
                                    "Qty: ${s.quantitySold} | Revenue: \$${s.totalRevenue.toStringAsFixed(2)}"),
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

                                    // ✅ NEW DELETE BUTTON
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
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
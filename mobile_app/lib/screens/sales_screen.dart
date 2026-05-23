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

  // ---------------- CREATE SALE ----------------
  Future<void> createSale(Map data) async {
    try {
      await ApiService.post("sales", data);
      fetchSales();
    } catch (e) {
      showError(e);
    }
  }

  void showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }

  // ---------------- DIALOG ----------------
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
              decoration: const InputDecoration(
                labelText: "Product Name or ID",
              ),
            ),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(
                labelText: "Quantity",
              ),
              keyboardType: TextInputType.number,
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

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showSaleDialog,
          )
        ],
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
                : ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final s = sales[index];

                      return Card(
                        child: ListTile(
                          title: Text(s.productName),
                          subtitle: Text("Qty sold: ${s.quantitySold}"),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("\$${s.totalRevenue}"),
                              Text(
                                "Profit: \$${s.profit}",
                                style: const TextStyle(fontSize: 12),
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
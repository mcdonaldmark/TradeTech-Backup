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
      final List data = res as List;

      setState(() {
        sales = data.map((item) => Sale.fromJson(item)).toList();
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
                : ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final s = sales[index];

                      return Card(
                        child: ListTile(
                          title: Text(s.productName),
                          subtitle: Text("Qty: ${s.quantitySold}"),
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
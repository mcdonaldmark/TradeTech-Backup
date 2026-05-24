import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  bool loading = true;
  String? error;

  double revenue = 0;
  double cost = 0;
  double profit = 0;

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService.get("sales/profit-loss");

      setState(() {
        revenue = double.tryParse(res["revenue"].toString()) ?? 0;
        cost = double.tryParse(res["cost"].toString()) ?? 0;
        profit = double.tryParse(res["profit"].toString()) ?? 0;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Widget buildCard(String title, double value, Color color) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          "\$${value.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profit & Loss"),
      ),
      body: RefreshIndicator(
        onRefresh: fetchSummary,
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
                          onPressed: fetchSummary,
                          child: const Text("Retry"),
                        ),
                      )
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      buildCard("Total Revenue", revenue, Colors.blue),
                      buildCard("Total Cost", cost, Colors.red),
                      buildCard(
                        "Total Profit",
                        profit,
                        profit >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
      ),
    );
  }
}
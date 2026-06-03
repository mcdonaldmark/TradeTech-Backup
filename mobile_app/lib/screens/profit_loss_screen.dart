import 'package:flutter/material.dart';
import 'dart:convert';

import '../core/api/api_service.dart';
import '../widgets/product_image.dart';

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

  List sales = [];
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    fetchSummary();
    fetchSales();
  }

  double _toNum(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  Future<void> fetchSummary() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService.get("sales/profit-loss");

      final data = (res is Map && res["data"] is Map) ? res["data"] : res;

      setState(() {
        revenue = _toNum(data["revenue"]);
        cost = _toNum(data["cost"]);
        profit = _toNum(data["profit"]);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> fetchSales() async {
    try {
      final res = await ApiService.get("sales");

      setState(() {
        sales = res;
      });

      print("FIRST SALE: ${sales.isNotEmpty ? sales.first : 'NO SALES'}");
    } catch (_) {}
  }

  bool inRange(DateTime date) {
    if (selectedDateRange == null) return true;

    final start = DateTime(
      selectedDateRange!.start.year,
      selectedDateRange!.start.month,
      selectedDateRange!.start.day,
    );

    final end = DateTime(
      selectedDateRange!.end.year,
      selectedDateRange!.end.month,
      selectedDateRange!.end.day,
      23,
      59,
      59,
    );

    return !date.isBefore(start) && !date.isAfter(end);
  }

  List get filteredSales {
    return sales.where((s) {
      final date =
          DateTime.tryParse(s["created_at"] ?? "") ?? DateTime.now();
      return inRange(date);
    }).toList();
  }

  double get filteredRevenue {
    double total = 0;

    for (final s in filteredSales) {
      final qty = _toNum(s["quantity_sold"]);
      final price = _toNum(s["price"] ?? s["unit_price"]);
      total += qty * price;
    }

    return total;
  }

  double get filteredCost {
    double total = 0;

    for (final s in filteredSales) {
      if (s["total_cost"] != null) {
        total += _toNum(s["total_cost"]);
        continue;
      }

      final qty = _toNum(s["quantity_sold"]);

      final costValue = _toNum(
        s["cost"] ??
            s["unit_cost"] ??
            s["product_cost"] ??
            s["buy_price"] ??
            s["purchase_price"] ??
            s["cost_price"],
      );

      total += qty * costValue;
    }

    return total;
  }

  double get filteredProfit => filteredRevenue - filteredCost;

  Map<String, int> get productTotals {
    final map = <String, int>{};

    for (final s in filteredSales) {
      final name = s["product_name"];

      if (name == null ||
          name.toString().trim().isEmpty ||
          name.toString().toLowerCase() == "deleted product") {
        continue;
      }

      final qty = _toNum(s["quantity_sold"]).toInt();
      map[name] = (map[name] ?? 0) + qty;
    }

    return map;
  }

  List<MapEntry<String, int>> get sortedProducts {
    final list = productTotals.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  String get bestProduct =>
      sortedProducts.isNotEmpty ? sortedProducts.first.key : "";

  String get worstProduct =>
      sortedProducts.isNotEmpty ? sortedProducts.last.key : "";

  String getProductImage(String name) {
    final match = filteredSales.firstWhere(
      (s) => s["product_name"] == name,
      orElse: () => {},
    );

    return match["image_url"] ??
        match["product_image"] ??
        match["image"] ??
        "";
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

  Future<void> pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: selectedDateRange,
    );

    if (range != null) {
      setState(() {
        selectedDateRange = range;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profit & Loss"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchSummary();
          await fetchSales();
        },
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
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.date_range),
                          title: const Text("Date Range"),
                          subtitle: Text(
                            selectedDateRange == null
                                ? "All Dates"
                                : "${selectedDateRange!.start.month}/${selectedDateRange!.start.day}/${selectedDateRange!.start.year}"
                                    " - "
                                    "${selectedDateRange!.end.month}/${selectedDateRange!.end.day}/${selectedDateRange!.end.year}",
                          ),
                          trailing: ElevatedButton(
                            onPressed: pickDateRange,
                            child: const Text("Select"),
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedDateRange = null;
                          });
                        },
                        child: const Text("Clear Filter"),
                      ),

                      const SizedBox(height: 16),

                      buildCard("Revenue (Filtered)", filteredRevenue, Colors.blue),
                      buildCard(
                        "Cost (Filtered)",
                        filteredCost,
                        Colors.red,
                      ),
                      buildCard(
                        "Profit (Filtered)",
                        filteredProfit,
                        filteredProfit >= 0 ? Colors.green : Colors.red,
                      ),

                      const SizedBox(height: 16),

                      Card(
                        child: ListTile(
                          title: const Text("Best Selling Product"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bestProduct),
                              if (getProductImage(bestProduct).isNotEmpty)
                                Image.memory(
                                  base64Decode(getProductImage(bestProduct)),
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Card(
                        child: ListTile(
                          title: const Text("Least Selling Product"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(worstProduct),
                              if (getProductImage(worstProduct).isNotEmpty)
                                Image.memory(
                                  base64Decode(getProductImage(worstProduct)),
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
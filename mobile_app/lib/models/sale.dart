class Sale {
  final int id;
  final String productName;
  final int quantitySold;
  final double totalRevenue;
  final double profit;
  final String createdAt;

  Sale({
    required this.id,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.profit,
    required this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json["id"] ?? 0,
      productName: json["product_name"] ?? "Unknown Product",
      quantitySold: json["quantity_sold"] ?? 0,
      totalRevenue: double.tryParse(json["total_revenue"]?.toString() ?? "0") ?? 0,
      profit: double.tryParse(json["profit"]?.toString() ?? "0") ?? 0,
      createdAt: json["created_at"] ?? "",
    );
  }
}
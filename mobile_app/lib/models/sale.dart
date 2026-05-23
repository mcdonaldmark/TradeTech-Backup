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
      id: json["id"],
      productName: json["product_name"],
      quantitySold: json["quantity_sold"],
      totalRevenue: double.parse(json["total_revenue"].toString()),
      profit: double.parse(json["profit"].toString()),
      createdAt: json["created_at"],
    );
  }
}
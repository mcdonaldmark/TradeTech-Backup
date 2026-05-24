class Order {
  final int id;
  final String userName;
  final double total;
  final String status;
  final String createdAt;

  Order({
    required this.id,
    required this.userName,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json["id"],
      userName: json["user_name"],
      total: double.parse(json["total"].toString()),
      status: json["status"],
      createdAt: json["created_at"],
    );
  }
}
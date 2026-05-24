class OrderItem {
  final int productId;
  final String name;
  final double price;
  int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;
}
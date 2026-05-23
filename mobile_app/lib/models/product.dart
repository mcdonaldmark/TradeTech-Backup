class Product {
  final int id;
  final String name;
  final String description;
  final int quantity;
  final double price;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"],
      name: json["name"],
      description: json["description"] ?? "",
      quantity: json["quantity"],
      price: double.parse(json["price"].toString()),
      imageUrl: json["image_url"],
    );
  }
}
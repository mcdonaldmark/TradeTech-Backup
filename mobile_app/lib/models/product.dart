class Product {
  final int id;
  final String name;
  final String description;
  final int quantity;
  final double price;

  final double? costPrice;

  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    this.costPrice,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,

      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0,

      costPrice: json['cost_price'] == null
          ? null
          : double.tryParse(json['cost_price'].toString()),

      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'price': price,

      'cost_price': costPrice,

      'image_url': imageUrl,
    };
  }
}
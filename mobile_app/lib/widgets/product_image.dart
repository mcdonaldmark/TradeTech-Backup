import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? url;
  final double size;

  const ProductImage({
    super.key,
    required this.url,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Icon(Icons.image, size: size);
    }

    return Image.network(
      url!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.broken_image, size: size),
    );
  }
}
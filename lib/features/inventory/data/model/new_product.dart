import 'package:cloud_firestore/cloud_firestore.dart';

/// Used for product creation form (Firestore insert only).
/// This is separate from Product model for clean architecture.
class NewProduct {
  final String name;
  final double price;
  final int stockCount;
  final bool inStock;
  final String category;
  final String description;
  final String? imageUrl; // Nullable for fallback image

  NewProduct({
    required this.name,
    required this.price,
    required this.stockCount,
    required this.inStock,
    required this.category,
    this.description = '',
    this.imageUrl,
  });

  /// Converts the product into a Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stockCount': stockCount,
      'inStock': inStock,
      'category': category,
      'description': description,
      'imageUrl': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
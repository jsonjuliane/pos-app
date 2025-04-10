import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product stored in Firestore.
class Product {
  /// Firestore document ID (used as unique key in app)
  final String id;

  /// Display name of the product
  final String name;

  /// Price per unit
  final double price;

  /// Category used for filtering (e.g., 'Snack', 'Platter')
  final String category;

  /// Number of items available in stock
  final int stockCount;

  /// Whether this product is available for ordering
  final bool inStock;

  /// Image URL of the product (can be local or hosted)
  final String imageUrl;

  /// Optional product description
  final String description;

  /// Date/time the product was added to Firestore
  final DateTime createdAt;

  /// Last updated timestamp
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.stockCount,
    required this.inStock,
    required this.imageUrl,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Product object from a Firestore document.
  factory Product.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      stockCount: data['stockCount'] ?? 0,
      inStock: data['inStock'] ?? false,
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
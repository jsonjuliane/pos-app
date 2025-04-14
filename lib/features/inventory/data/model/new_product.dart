import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../dashboard/products/data/models/product.dart';

/// Used for product creation form (Firestore insert only).
///
/// Clean architecture: Matches Product structure.
class NewProduct {
  /// Display name of the product.
  final String name;

  /// List of price variants. Must have at least 1 element.
  final List<PriceVariant> prices;

  /// Available stock count.
  final int stockCount;

  /// Whether the product is active/available for ordering.
  final bool enabled;

  /// Category name (e.g., 'Snack', 'Platter').
  final String category;

  /// Optional product description.
  final String description;

  /// Optional image URL (nullable for fallback/default image).
  final String? imageUrl;

  NewProduct({
    required this.name,
    required this.prices,
    required this.stockCount,
    required this.enabled,
    required this.category,
    this.description = '',
    this.imageUrl,
  }) : assert(prices.isNotEmpty, 'Prices list must contain at least one variant');

  /// Converts this product object into a Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'prices': prices.map((e) => e.toMap()).toList(),
      'stockCount': stockCount,
      'enabled': enabled,
      'category': category,
      'description': description,
      'imageUrl': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

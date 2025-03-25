import 'package:flutter/foundation.dart';

/// Represents a product that can be shown on the product grid
/// and added to an order.
///
/// This is a temporary in-memory model for UI logic only.
/// It may later be converted into a Hive or API-backed model.
@immutable
class Product {
  /// Unique identifier for this product
  final String id;

  /// Display name of the product
  final String name;

  /// Local asset image path or network URL (for now we'll use local)
  final String imagePath;

  /// Category of the product (used for filtering)
  final String category;

  /// Base price of the product
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.category,
    required this.price,
  });

}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product stored in Firestore.
class Product {
  /// Firestore document ID (used as unique key in app)
  final String id;

  /// Display name of the product
  final String name;

  /// Optional list of price variants (only used if [hasPriceVariants] is true)
  ///
  /// Example use case:
  /// - Quarter / Half / Whole sizes
  /// - Small / Medium / Large options
  final List<PriceVariant> prices;

  /// Category used for filtering (e.g., 'Snack', 'Platter')
  final String category;

  /// Number of items available in stock
  final int stockCount;

  /// Whether this product is available for ordering
  final bool enabled;

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
    required this.prices,
    required this.category,
    required this.stockCount,
    required this.enabled,
    required this.imageUrl,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasPriceVariants => prices.length > 1;

  double get price => prices.first.price;

  /// Creates a Product object from a Firestore document.
  factory Product.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      prices: (data['prices'] as List<dynamic>? ?? [])
          .map((e) => PriceVariant.fromMap(e as Map<String, dynamic>))
          .toList(),
      category: data['category'] ?? '',
      stockCount: data['stockCount'] ?? 0,
      enabled: data['enabled'] ?? false,
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Represents a single price variant for a product.
class PriceVariant {
  /// Name of the variant (e.g., 'Quarter', 'Half', 'Whole')
  final String name;

  /// Price of this variant
  final double price;

  const PriceVariant({
    required this.name,
    required this.price,
  });

  /// Creates a PriceVariant from Firestore map data.
  factory PriceVariant.fromMap(Map<String, dynamic> map) {
    return PriceVariant(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  /// Converts PriceVariant to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }
}
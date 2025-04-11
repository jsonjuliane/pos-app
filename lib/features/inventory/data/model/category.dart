import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product category.
class Category {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  /// Creates a Category object from Firestore document.
  factory Category.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}

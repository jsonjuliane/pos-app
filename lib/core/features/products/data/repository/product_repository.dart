import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

/// Responsible for interacting with the Firestore `products` collection.
class ProductRepository {
  final _productRef = FirebaseFirestore.instance.collection('products');

  /// Returns a real-time stream of product list ordered by creation date.
  Stream<List<Product>> getProducts() {
    return _productRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromDoc(doc)).toList());
  }
}
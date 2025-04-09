import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/product.dart';

/// Responsible for interacting with the Firestore `products` collection.
class ProductRepository {
  /// Fetches products for a specific branch from its subcollection.
  Stream<List<Product>> getProducts({required String branchId}) {
    final productRef = FirebaseFirestore.instance
        .collection('branches')
        .doc(branchId)
        .collection('products');

    return productRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromDoc(doc)).toList());
  }
}
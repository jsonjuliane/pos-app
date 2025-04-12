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

  /// Decreases stock count by [quantity] (used when adding to cart)
  Future<void> decreaseStock({
    required String branchId,
    required String productId,
    required int quantity,
  }) async {
    final productRef = FirebaseFirestore.instance
        .collection('branches')
        .doc(branchId)
        .collection('products')
        .doc(productId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      final currentStock = snapshot.get('stockCount') as int;

      if (currentStock < quantity) {
        throw Exception('Not enough stock');
      }

      transaction.update(productRef, {
        'stockCount': currentStock - quantity,
      });
    });
  }

  /// Increases stock count by [quantity] (used when removing from cart)
  Future<void> increaseStock({
    required String branchId,
    required String productId,
    required int quantity,
  }) async {
    final productRef = FirebaseFirestore.instance
        .collection('branches')
        .doc(branchId)
        .collection('products')
        .doc(productId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      final currentStock = snapshot.get('stockCount') as int;

      transaction.update(productRef, {
        'stockCount': currentStock + quantity,
      });
    });
  }
}
// inventory/data/repositories/inventory_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dashboard/products/data/models/product.dart';

class InventoryRepository {
  final _firestore = FirebaseFirestore.instance;

  Stream<List<Product>> getProducts({required String branchId}) {
    return _firestore
        .collection('branches')
        .doc(branchId)
        .collection('products')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromDoc).toList());
  }

// CRUD methods to follow...
}
// inventory/data/repositories/inventory_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/utils/error_handler.dart';
import '../../dashboard/products/data/models/product.dart';
import '../data/model/category.dart';
import '../data/model/new_product.dart';

/// Repository for handling inventory-related Firestore operations.
class InventoryRepository {
  final _firestore = FirebaseFirestore.instance;

  /// Fetches all products for a specific branch.
  Stream<List<Product>> getProducts({required String branchId}) {
    return _firestore
        .collection('branches')
        .doc(branchId)
        .collection('products')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromDoc(doc)).toList());
  }

  /// Adds a new product under the given branch.
  Future<void> addProduct({
    required String branchId,
    required NewProduct product,
  }) async {
    try {
      await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('products')
          .add(product.toMap());
    } on FirebaseException catch (e) {
      throw Exception(mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to add product. Please try again.');
    }
  }

  /// Updates an existing product in a branch.
  Future<void> updateProduct({
    required String branchId,
    required String productId,
    required NewProduct product,
  }) async {
    try {
      await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('products')
          .doc(productId)
          .update({
        ...product.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception(mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to add product. Please try again.');
    }
  }

  /// Deletes a product from a branch by ID.
  Future<void> deleteProduct({
    required String branchId,
    required String productId,
  }) async {
    try {
      await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('products')
          .doc(productId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception(mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to add product. Please try again.');
    }
  }

  /// Fetches all categories for a specific branch.
  Stream<List<Category>> getCategories({required String branchId}) {
    return _firestore
        .collection('branches')
        .doc(branchId)
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Category.fromDoc(doc)).toList());
  }

  /// Adds a category from a branch by ID.
  Future<void> addCategory({
    required String branchId,
    required String name,
  }) async {
    await _firestore
        .collection('branches')
        .doc(branchId)
        .collection('categories')
        .add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a category by ID under a specific branch.
  Future<void> deleteCategory({
    required String branchId,
    required String categoryId,
  }) async {
    await _firestore
        .collection('branches')
        .doc(branchId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }
}
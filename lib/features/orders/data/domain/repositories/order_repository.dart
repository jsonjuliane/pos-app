import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product_order.dart';

class OrderRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createOrder({
    required String branchId,
    required ProductOrder order,
  }) async {
    final orderRef = _firestore
        .collection('branches')
        .doc(branchId)
        .collection('orders')
        .doc();

    await orderRef.set(order.toMap());
  }

  Stream<List<ProductOrder>> getOrders(String branchId) {
    return _firestore
        .collection('branches')
        .doc(branchId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ProductOrder.fromDoc(doc))
        .toList());
  }

  Future<void> updateOrder({
    required String branchId,
    required String orderId,
    required Map<String, dynamic> data,
  }) async {
    final orderRef = _firestore
        .collection('branches')
        .doc(branchId)
        .collection('orders')
        .doc(orderId);

    await orderRef.update(data);
  }

  Future<void> markAsPaid({
    required String branchId,
    required String orderId,
  }) async {
    await updateOrder(
      branchId: branchId,
      orderId: orderId,
      data: {
        'paid': true,
        'updatedAt': DateTime.now(),
      },
    );
  }

  Future<void> markAsCompleted({
    required String branchId,
    required String orderId,
  }) async {
    await updateOrder(
      branchId: branchId,
      orderId: orderId,
      data: {
        'completed': true,
        'updatedAt': DateTime.now(),
      },
    );
  }
}

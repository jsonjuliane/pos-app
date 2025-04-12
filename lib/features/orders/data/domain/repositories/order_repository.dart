import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos_app/features/orders/data/models/product_order.dart';

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
}
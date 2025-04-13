import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_item.dart';

class ProductOrder {
  final String id;
  final String customerName;
  final String branchId;
  final bool paid;
  final double paymentAmount;
  final double totalAmount;
  final bool discountApplied;
  final double discountAmount;
  final bool completed; // <-- New Field
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductOrder({
    required this.id,
    required this.customerName,
    required this.branchId,
    required this.paid,
    required this.paymentAmount,
    required this.totalAmount,
    required this.discountApplied,
    required this.discountAmount,
    required this.completed, // <-- Required Now
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'branchId': branchId,
      'paid': paid,
      'paymentAmount': paymentAmount,
      'totalAmount': totalAmount,
      'discountApplied': discountApplied,
      'discountAmount': discountAmount,
      'completed': completed,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ProductOrder.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductOrder(
      id: doc.id,
      customerName: data['customerName'],
      branchId: data['branchId'],
      paid: data['paid'],
      paymentAmount: (data['paymentAmount'] as num).toDouble(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      discountApplied: data['discountApplied'],
      discountAmount: (data['discountAmount'] as num).toDouble(),
      completed: data['completed'] ?? false, // Default false
      items: (data['items'] as List)
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
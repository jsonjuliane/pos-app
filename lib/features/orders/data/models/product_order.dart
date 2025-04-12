import 'order_item.dart';

class ProductOrder {
  final String id;
  final String branchId;
  final bool paid;
  final double paymentAmount;
  final double totalAmount;
  final bool discountApplied;
  final double discountAmount;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductOrder({
    required this.id,
    required this.branchId,
    required this.paid,
    required this.paymentAmount,
    required this.totalAmount,
    required this.discountApplied,
    required this.discountAmount,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'paid': paid,
      'paymentAmount': paymentAmount,
      'totalAmount': totalAmount,
      'discountApplied': discountApplied,
      'discountAmount': discountAmount,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

import 'package:flutter/src/widgets/framework.dart';

class SalesSummary {
  final double grossSales;
  final double totalDiscount;
  final double netSales;
  final double paymentCollected;
  final int totalItemsSold;
  final List<SalesSummaryItem> items;
  final DateTime date;

  SalesSummary({
    required this.grossSales,
    required this.totalDiscount,
    required this.netSales,
    required this.paymentCollected,
    required this.totalItemsSold,
    required this.items,
    required this.date,
  });

  /// ✅ Added copyWith for SalesSummary
  SalesSummary copyWith({
    double? grossSales,
    double? totalDiscount,
    double? netSales,
    double? paymentCollected,
    int? totalItemsSold,
    List<SalesSummaryItem>? items,
    DateTime? date,
  }) {
    return SalesSummary(
      grossSales: grossSales ?? this.grossSales,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      netSales: netSales ?? this.netSales,
      paymentCollected: paymentCollected ?? this.paymentCollected,
      totalItemsSold: totalItemsSold ?? this.totalItemsSold,
      items: items ?? this.items,
      date: date ?? this.date,
    );
  }

}

class SalesSummaryItem {
  final String productId;
  final String name;
  final double price;
  final bool discounted;
  final int quantity;
  final double subtotal;
  final double discount;
  final String? category;

  SalesSummaryItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.discounted,
    required this.quantity,
    required this.subtotal,
    required this.discount,
    this.category,
  });

}
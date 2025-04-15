class SalesSummary {
  final double grossSales;
  final double totalDiscount;
  final double netSales;
  final double paymentCollected;
  final int totalItemsSold;
  final List<SalesSummaryItem> items;

  SalesSummary({
    required this.grossSales,
    required this.totalDiscount,
    required this.netSales,
    required this.paymentCollected,
    required this.totalItemsSold,
    required this.items,
  });
}

class SalesSummaryItem {
  final String productId;
  final String name;
  final double price;
  final bool discounted;
  final int quantity;
  final double subtotal;
  final double discount;

  SalesSummaryItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.discounted,
    required this.quantity,
    required this.subtotal,
    required this.discount,
  });
}
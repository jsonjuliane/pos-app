class OrderItem {
  final String productId;
  final String customerName;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;

    OrderItem({
    required this.productId,
    required this.customerName,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'customerName' : customerName,
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}
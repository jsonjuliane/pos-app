import 'package:flutter/material.dart';
import '../../../products/data/models/product.dart';

/// Represents a product added to the cart, with quantity and price variant.
@immutable
class CartItem {
  /// The associated product, including the selected price variant (single variant in [product.prices])
  final Product product;

  /// Quantity of this variant in the cart
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  /// Returns a copy of this item with the updated quantity.
  CartItem copyWithQuantity(int newQuantity) {
    return CartItem(
      product: product,
      quantity: newQuantity.clamp(0, double.infinity).toInt(),
    );
  }

  /// Total = quantity × selected variant price
  double get totalPrice => quantity * product.price;

  /// Used for comparison: same product ID and same selected price variant
  @override
  bool operator ==(Object other) {
    return other is CartItem &&
        other.product.id == product.id &&
        other.product.price == product.price;
  }

  @override
  int get hashCode => Object.hash(product.id, product.price);
}
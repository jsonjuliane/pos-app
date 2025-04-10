import 'package:flutter/material.dart';
import '../../../products/data/models/product.dart';

/// Represents a product added to the cart, with quantity.
@immutable
class CartItem {
  /// The associated product
  final Product product;

  /// How many of this product are in the cart
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  /// Returns a new copy of the item with updated quantity.
  CartItem copyWithQuantity(int newQuantity) {
    return CartItem(
      product: product,
      quantity: newQuantity.clamp(0, double.infinity).toInt(),
    );
  }

  /// Computes total price based on quantity × product price
  double get totalPrice => quantity * product.price;
}
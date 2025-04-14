import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/data/models/product.dart';
import '../data/models/cart_item.dart';

/// Manages the cart state locally using a list of [CartItem].
/// Only performs local stock checking when adding/removing items.
/// Firestore stock update happens only on Checkout.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Adds a product to the cart.
  /// Checks against product.stockCount for available stock.
  void add(Product product, {required void Function(String message) onError}) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    final existingQuantity = index == -1 ? 0 : state[index].quantity;

    if (existingQuantity >= product.stockCount) {
      onError('Out of stock');
      return;
    }

    if (index == -1) {
      state = [...state, CartItem(product: product, quantity: 1)];
    } else {
      final updated = state[index].copyWithQuantity(existingQuantity + 1);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Removes one quantity of a product from the cart.
  /// If quantity reaches zero, removes the product.
  void remove(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) return;

    final current = state[index];

    if (current.quantity == 1) {
      state = [
        ...state.sublist(0, index),
        ...state.sublist(index + 1),
      ];
    } else {
      final updated = current.copyWithQuantity(current.quantity - 1);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Clears the entire cart (used after successful checkout)
  void clear() => state = [];
}
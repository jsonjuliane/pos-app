import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cart_item.dart';
import '../../../products/data/models/product.dart';

/// Manages the cart state globally using a list of [CartItem].
/// Allows adding, removing, and clearing items from the cart.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Adds a product to the cart. If already present, increments quantity.
  void add(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, quantity: 1)];
    } else {
      final updated = state[index].copyWithQuantity(state[index].quantity + 1);
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

  /// Clears the entire cart
  void clear() => state = [];
}
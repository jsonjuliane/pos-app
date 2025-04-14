import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/data/models/product.dart';
import '../data/models/cart_item.dart';

/// Manages local cart state. Handles quantity and duplicate variant logic.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Adds a product to the cart. Differentiates based on product ID + price.
  void add(Product product, {required void Function(String message) onError}) {
    final index = state.indexWhere(
          (item) => item.product.id == product.id && item.product.price == product.price,
    );

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

  /// Removes one quantity of the selected variant of a product.
  void remove(Product product) {
    final index = state.indexWhere(
          (item) => item.product.id == product.id && item.product.price == product.price,
    );
    if (index == -1) return;

    final current = state[index];
    if (current.quantity <= 1) {
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

  /// Clears the entire cart.
  void clear() => state = [];
}
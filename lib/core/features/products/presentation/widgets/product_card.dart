import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../cart/data/models/cart_item.dart';
import '../../../cart/data/providers/cart_providers.dart';
import '../../data/models/product.dart';

/// A product card that:
/// - Adds product to cart on tap
/// - Removes one from cart on long press
class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartItem = cart.firstWhere(
          (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );

    return GestureDetector(
      onTap: () => ref.read(cartProvider.notifier).add(product),
      onLongPress: () => ref.read(cartProvider.notifier).remove(product),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  product.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '₱${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                cartItem.quantity > 0
                    ? 'In cart: ${cartItem.quantity}'
                    : 'Tap to add • Long press to remove',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: cartItem.quantity > 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
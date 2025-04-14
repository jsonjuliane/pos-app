import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/dashboard/products/presentation/widgets/variant_selector_dialog.dart';

import '../../../cart/data/models/cart_item.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/models/product.dart';

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

    final theme = Theme.of(context);
    final isOutOfStockOrDisabled = product.stockCount == 0 || !product.enabled;

    // Format prices
    final priceDisplay = product.prices
        .map((p) => '₱${p.price.toStringAsFixed(0)}')
        .join(' / ');

    return Opacity(
      opacity: isOutOfStockOrDisabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: () {
          if (product.hasPriceVariants) {
            showDialog(
              context: context,
              builder: (_) => VariantSelectorDialog(product: product),
            );
          } else {
            ref.read(cartProvider.notifier).add(product, onError: (msg) {
              // TODO: Optional error handling
            });
          }
        },
        onLongPress: () => ref.read(cartProvider.notifier).remove(product),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Product Name
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                /// Optional Description
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                /// Category
                Text(
                  product.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),

                const SizedBox(height: 8),

                /// Prices
                Text(
                  priceDisplay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                /// Stock & Enabled Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.stockCount > 0
                            ? 'Stock: ${product.stockCount}'
                            : 'Out of Stock',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: product.stockCount > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        product.enabled ? 'Enabled' : 'Disabled',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: product.enabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                /// Cart Info
                Text(
                  cartItem.quantity > 0
                      ? 'In cart: ${cartItem.quantity}'
                      : 'Tap to add • Long press to remove',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cartItem.quantity > 0
                        ? theme.colorScheme.primary
                        : theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/models/product.dart';

/// Dialog for selecting a price variant when product has multiple variants.
/// Clean and reusable.
class VariantSelectorDialog extends ConsumerWidget {
  final Product product;

  const VariantSelectorDialog({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Select Variant for ${product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: product.prices.map((variant) {
          return ListTile(
            title: Text(
              '${variant.name} - ₱${variant.price.toStringAsFixed(2)}',
            ),
            onTap: () {
              // Re-create Product with only selected price variant
              final selectedProduct = Product(
                id: product.id,
                name: product.name,
                prices: [variant],
                category: product.category,
                stockCount: product.stockCount,
                enabled: product.enabled,
                imageUrl: product.imageUrl,
                description: product.description,
                createdAt: product.createdAt,
                updatedAt: product.updatedAt,
              );

              ref.read(cartProvider.notifier).add(selectedProduct, onError: (msg) {
                // Optional error handling
              });

              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }
}
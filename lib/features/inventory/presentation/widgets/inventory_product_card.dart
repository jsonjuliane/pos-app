import 'package:flutter/material.dart';
import 'package:pos_app/features/dashboard/products/data/models/product.dart';

class InventoryProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isOwner; // Add this

  const InventoryProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = product.imageUrl.isNotEmpty;
    const fallbackImage = 'assets/images/special_wow_seafood.jpg';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: hasImage
                ? Image.network(product.imageUrl, fit: BoxFit.cover)
                : Image.asset(fallbackImage, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('₱${product.price.toStringAsFixed(2)}'),
                Text('Stock: ${product.stockCount}'),
                Text(
                  product.stockCount > 0 ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    color: product.stockCount > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
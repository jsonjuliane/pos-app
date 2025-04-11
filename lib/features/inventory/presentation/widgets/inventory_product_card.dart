import 'package:flutter/material.dart';
import 'package:pos_app/features/dashboard/products/data/models/product.dart';

class InventoryProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isOwner;

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
            child:
                hasImage
                    ? Image.network(product.imageUrl, fit: BoxFit.cover)
                    : Image.asset(fallbackImage, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                Text(
                  product.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Price & Stock Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Stock: ${product.stockCount}',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // In Stock & Enabled Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.stockCount > 0 ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          color:
                              product.stockCount > 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        product.enabled ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          color:
                              product.enabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
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

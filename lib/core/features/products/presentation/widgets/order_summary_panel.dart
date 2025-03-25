import 'package:flutter/material.dart';

import '../../data/models/product.dart';

/// Displays a summary of selected products.
/// This version uses a hardcoded list of items for now.
/// Will be refactored to use Riverpod/global cart state later.
class OrderSummaryPanel extends StatelessWidget {
  final List<Product> selectedItems;

  const OrderSummaryPanel({super.key, required this.selectedItems});

  @override
  Widget build(BuildContext context) {
    final total = selectedItems.fold<double>(
      0,
          (sum, item) => sum + item.selectedCount * _mockPrice(item),
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧾 Order Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // List of selected products
          Expanded(
            child: ListView.builder(
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                final product = selectedItems[index];
                return _OrderItem(product: product);
              },
            ),
          ),

          // Total + Checkout
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Checkout'),
            ),
          )
        ],
      ),
    );
  }

  /// Temporary price per product (could come from product.price later)
  double _mockPrice(Product product) {
    return 50 + product.id.length * 10; // Dummy pricing
  }
}

/// Renders a single item row in the order list
class _OrderItem extends StatelessWidget {
  final Product product;

  const _OrderItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text('x${product.selectedCount}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              // TODO: Hook up with shared cart state (Riverpod)
            },
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            onPressed: () {
              // TODO: Hook up with shared cart state (Riverpod)
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
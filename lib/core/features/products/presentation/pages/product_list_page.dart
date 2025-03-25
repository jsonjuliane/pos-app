import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/data/providers/cart_providers.dart';
import '../../data/models/product.dart';
import '../widgets/order_summary_panel.dart';
import '../widgets/product_card.dart';

final List<Product> mockProducts = [
  Product(id: '1', name: 'Boom Sarap', imagePath: 'assets/images/boom_sarap.jpg', category: 'Platter', price: 99.0),
  Product(id: '2', name: 'Wow Seafood', imagePath: 'assets/images/wow_seafood.jpg', category: 'Platter', price: 120.0),
  Product(id: '3', name: 'Singaporean Fishballs', imagePath: 'assets/images/special_wow_seafood.jpg', category: 'Snack', price: 85.0),
  Product(id: '4', name: 'Fishcake', imagePath: 'assets/images/boom_sarap.jpg', category: 'Snack', price: 75.0),
  Product(id: '5', name: 'Golden Cheeseballs', imagePath: 'assets/images/wow_seafood.jpg', category: 'Snack', price: 35.0),
  Product(id: '6', name: '1 Day Old Chick', imagePath: 'assets/images/special_wow_seafood.jpg', category: 'Snack', price: 80.0),
  Product(id: '7', name: 'Kwek kwek', imagePath: 'assets/images/boom_sarap.jpg', category: 'Snack', price: 55.0),
  Product(id: '8', name: 'Cheese Stick', imagePath: 'assets/images/wow_seafood.jpg', category: 'Snack', price: 38.0),
];

/// Main screen showing the product grid and order summary (for tablets/web).
class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final cartItems = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: isWide
          ? Row(
        children: [
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ProductGrid(products: mockProducts),
            ),
          ),
          Expanded(
            flex: 3,
            child: OrderSummaryPanel(selectedItems: cartItems),
          ),
        ],
      )
          : const Center(child: Text('Mobile layout coming soon')),
    );
  }
}

class ProductGrid extends StatelessWidget {
  final List<Product> products;

  const ProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}
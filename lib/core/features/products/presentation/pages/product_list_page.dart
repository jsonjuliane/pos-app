import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../widgets/product_card.dart';

/// Temporary list of mock products.
/// In the future, this will be fetched from a local DB or API.
final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'Boom Sarap',
    imagePath: 'assets/images/boom_sarap.jpg',
    category: 'Platter',
  ),
  Product(
    id: '2',
    name: 'Wow Seafood',
    imagePath: 'assets/images/wow_seafood.jpg',
    category: 'Platter',
  ),
  Product(
    id: '3',
    name: 'Singaporean Fishballs',
    imagePath: 'assets/images/special_wow_seafood.jpg',
    category: 'Snack',
  ),
  Product(
    id: '4',
    name: 'Fishcake',
    imagePath: 'assets/images/boom_sarap.jpg',
    category: 'Snack',
  ),
  Product(
    id: '5',
    name: 'Golden Cheeseballs',
    imagePath: 'assets/images/wow_seafood.jpg',
    category: 'Snack',
  ),
  // Add more as needed...
];

/// Main screen showing the product grid and order summary
/// This version is optimized for web, desktop, and tablet views.
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We use LayoutBuilder to detect screen width and switch layout modes.
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Products'),
          ),
          body: isWide
              ? Row(
            children: [
              // Product Grid (Left Panel - takes ~70% of width)
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ProductGrid(products: mockProducts),
                ),
              ),

              // Order Summary (Right Panel - to be added next)
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: Text('🧾 Order Summary Panel (Coming Next)'),
                  ),
                ),
              ),
            ],
          )
              : const Center(
            child: Text(
              'Mobile layout coming soon',
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}

/// Renders the list of products in a grid layout.
/// This widget works well for wide screens like tablets and desktops.
class ProductGrid extends StatelessWidget {
  final List<Product> products;

  const ProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 cards per row for wide screens
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(product: product);
      },
    );
  }
}

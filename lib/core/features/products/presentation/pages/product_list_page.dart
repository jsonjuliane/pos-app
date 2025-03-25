import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/data/providers/cart_providers.dart';
import '../../data/models/product.dart';
import '../../data/providers/category_provider.dart';
import '../../presentation/widgets/category_selector.dart';
import '../../presentation/widgets/order_summary_panel.dart';
import '../../presentation/widgets/product_card.dart';

/// Mock list of products for display and filtering.
/// Each product has a name, image, category, and price.
final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'Boom Sarap',
    imagePath: 'assets/images/boom_sarap.jpg',
    category: 'platter',
    price: 99.0,
  ),
  Product(
    id: '2',
    name: 'Wow Seafood',
    imagePath: 'assets/images/wow_seafood.jpg',
    category: 'platter',
    price: 120.0,
  ),
  Product(
    id: '3',
    name: 'Singaporean Fishballs',
    imagePath: 'assets/images/special_wow_seafood.jpg',
    category: 'snack',
    price: 85.0,
  ),
  Product(
    id: '4',
    name: 'Fishcake',
    imagePath: 'assets/images/boom_sarap.jpg',
    category: 'snack',
    price: 75.0,
  ),
  Product(
    id: '5',
    name: 'Golden Cheeseballs',
    imagePath: 'assets/images/wow_seafood.jpg',
    category: 'snack',
    price: 35.0,
  ),
  Product(
    id: '6',
    name: '1 Day Old Chick',
    imagePath: 'assets/images/special_wow_seafood.jpg',
    category: 'snack',
    price: 80.0,
  ),
  Product(
    id: '7',
    name: 'Kwek kwek',
    imagePath: 'assets/images/boom_sarap.jpg',
    category: 'snack',
    price: 55.0,
  ),
  Product(
    id: '8',
    name: 'Cheese Stick',
    imagePath: 'assets/images/wow_seafood.jpg',
    category: 'snack',
    price: 38.0,
  ),
];

/// Main product list screen for wide layouts (tablet, desktop, web).
/// Shows category filter, scrollable grid, and order summary.
class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Manually listen to category changes (outside build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual<String>(selectedCategoryProvider, (_, __) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final cartItems = ref.watch(cartProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    // Apply category filter to product list
    final filteredProducts =
        selectedCategory == 'all'
            ? mockProducts
            : mockProducts
                .where((p) => p.category.toLowerCase() == selectedCategory)
                .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body:
          isWide
              ? Row(
                children: [
                  // Left panel: Category chips + Product grid
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const CategorySelector(),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ProductGrid(
                              products: filteredProducts,
                              controller: _scrollController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right panel: Cart summary
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

/// Renders the product cards in a responsive grid.
/// Receives a scroll controller to enable scroll-to-top.
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final ScrollController controller;

  const ProductGrid({
    super.key,
    required this.products,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
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

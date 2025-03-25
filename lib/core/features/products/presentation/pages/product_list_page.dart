import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/data/providers/cart_providers.dart';
import '../../data/models/product.dart';
import '../../data/providers/category_provider.dart';
import '../../data/providers/product_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/order_summary_panel.dart';
import '../widgets/product_card.dart';

/// Main product list page for wide layouts (tablet, desktop, web).
/// Displays category selector, scrollable product grid, and order summary.
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

    // Scroll to top when selected category changes
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
    final productListAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: isWide
          ? Row(
        children: [
          // Left panel: Category selector + product grid
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // When loaded, pass products to the CategorySelector
                  productListAsync.when(
                    data: (products) => CategorySelector(products: products),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 12),

                  // Product grid
                  Expanded(
                    child: productListAsync.when(
                      data: (products) {
                        final selectedCategory = ref.watch(selectedCategoryProvider);
                        final filtered = selectedCategory.toLowerCase() == 'all'
                            ? products
                            : products
                            .where((p) =>
                        p.category.toLowerCase() ==
                            selectedCategory.toLowerCase())
                            .toList();

                        return ProductGrid(
                          products: filtered,
                          controller: _scrollController,
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) =>
                          Center(child: Text('Error loading products: $err')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right panel: Order summary
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

/// Responsive grid of product cards.
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

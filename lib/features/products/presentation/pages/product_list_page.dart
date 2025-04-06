import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';
import '../../../cart/data/models/cart_item.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/order_summary_panel.dart';
import '../../data/models/product.dart';
import '../providers/product_providers.dart';
import '../providers/selected_category_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/product_card.dart';

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
    final authUserAsync = ref.watch(authUserProvider);
    final productListAsync = ref.watch(productListProvider);

    if (authUserAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (authUserAsync.hasError) {
      return ErrorMessageWidget(
        message: mapFirestoreError(authUserAsync.error),
        onRetry: () => ref.refresh(authUserProvider),
      );
    }

    final user = authUserAsync.value;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final cartItems = ref.watch(cartProvider);

    return productListAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorMessageWidget(
        message: mapFirestoreError(err),
        onRetry: () => ref.refresh(productListProvider),
      ),
      data: (products) => _MainContent(
        scrollController: _scrollController,
        products: products,
        cartItems: cartItems,
      ),
    );
  }
}

class _MainContent extends ConsumerWidget {
  final ScrollController scrollController;
  final List<Product> products;
  final List<CartItem> cartItems;

  const _MainContent({
    required this.scrollController,
    required this.products,
    required this.cartItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filtered = selectedCategory.toLowerCase() == 'all'
        ? products
        : products
        .where((p) =>
    p.category.toLowerCase() == selectedCategory.toLowerCase())
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Row(
          children: [
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CategorySelector(products: products),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 3 / 4,
                        ),
                        itemBuilder: (context, index) {
                          return ProductCard(product: filtered[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isWide)
              Expanded(
                flex: 3,
                child: OrderSummaryPanel(selectedItems: cartItems),
              ),
          ],
        );
      },
    );
  }
}

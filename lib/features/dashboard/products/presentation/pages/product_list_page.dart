import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/auth/presentation/providers/auth_user_providers.dart';
import 'package:pos_app/features/dashboard/products/presentation/providers/selected_branch_provider.dart';
import 'package:pos_app/features/dashboard/products/presentation/providers/selected_category_provider.dart';
import 'package:pos_app/features/dashboard/products/presentation/widgets/category_selector.dart';
import 'package:pos_app/features/dashboard/products/presentation/widgets/product_card.dart';
import 'package:pos_app/features/user_management/data/providers/branch_provider.dart';
import 'package:pos_app/shared/utils/device_helper.dart';
import 'package:pos_app/shared/utils/error_handler.dart';
import 'package:pos_app/shared/widgets/error_message_widget.dart';
import 'package:pos_app/shared/widgets/select_branch_dialog.dart';

import '../../../../inventory/data/providers/inventory_list_provider.dart';
import '../../../cart/data/models/cart_item.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/order_summary_panel.dart';
import '../../data/models/product.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Listen for changes in the selected category to reset the scroll position.
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
    // Auth user state, product list and branch selection.
    final authUserAsync = ref.watch(authUserProvider);
    final productListAsync = ref.watch(inventoryListProvider);
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

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

    // For owners with no selected branch, show the branch selection dialog.
    if (user.role == 'owner' && selectedBranchId == null) {
      final branchesAsync = ref.watch(allBranchesProvider);
      return Center(
        child: ElevatedButton(
          onPressed:
              branchesAsync.isLoading
                  ? null
                  : () {
                    showDialog(
                      context: context,
                      builder: (_) => const SelectBranchDialog(),
                    );
                  },
          child:
              branchesAsync.isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Select Branch'),
        ),
      );
    }

    final cartItems = ref.watch(cartProvider);
    final branchNamesAsync = ref.watch(branchNamesProvider);
    String branchName = 'POS App'; // Default fallback.
    if (user.role == 'owner' && selectedBranchId != null) {
      final namesMap = branchNamesAsync.valueOrNull;
      branchName = namesMap?[selectedBranchId] ?? 'POS App';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(branchName),
        actions: [
          if (user.role == 'owner')
            IconButton(
              tooltip: 'Change Branch',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SelectBranchDialog(),
                );
              },
            ),
        ],
      ),
      body: productListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, _) => ErrorMessageWidget(
              message: mapFirestoreError(err),
              onRetry: () => ref.refresh(inventoryListProvider),
            ),
        data:
            (products) => _MainContent(
              scrollController: _scrollController,
              products: products,
              cartItems: cartItems,
            ),
      ),
    );
  }
}

/// _MainContent displays the category selector and the filtered product grid.
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

    // Filter out products based on the selected category
    final filtered =
        (selectedCategory.toLowerCase() == 'all'
              ? products
              : products
                  .where(
                    (p) =>
                        p.category.toLowerCase() ==
                        selectedCategory.toLowerCase(),
                  )
                  .toList())
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    final inStockProducts =
        filtered.where((p) => p.stockCount > 0 && p.enabled).toList();
    final outOfStockProducts =
        filtered.where((p) => p.stockCount == 0 || !p.enabled).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        // Wrap your entire portion (the category selector + product grid)
        // with a Padding widget that uses EdgeInsets.all(16) or symmetric(16).
        return Padding(
          padding: const EdgeInsets.all(16),
          // or EdgeInsets.symmetric(horizontal: 16)
          child:
              isWide
                  ? Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // The CategorySelector is inside the same padding
                            CategorySelector(products: products),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _ProductGrid(
                                scrollController: scrollController,
                                inStock: inStockProducts,
                                outOfStock: outOfStockProducts,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: OrderSummaryPanel(selectedItems: cartItems),
                      ),
                    ],
                  )
                  : Stack(
                    children: [
                      Column(
                        children: [
                          CategorySelector(products: products),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _ProductGrid(
                              scrollController: scrollController,
                              inStock: inStockProducts,
                              outOfStock: outOfStockProducts,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => const _OrderSummarySheet(),
                                );
                              },
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('View Cart'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
        );
      },
    );
  }
}

/// _ProductGrid builds the grid of product cards.
class _ProductGrid extends StatelessWidget {
  final ScrollController scrollController;
  final List<Product> inStock;
  final List<Product> outOfStock;

  const _ProductGrid({
    required this.scrollController,
    required this.inStock,
    required this.outOfStock,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = DeviceHelper.getDeviceType(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Build grid for in-stock products.
        Expanded(
          child: ListView(
            controller: scrollController,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inStock.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: DeviceHelper.getCrossAxisCount(
                    deviceType,
                    false,
                  ),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: DeviceHelper.getChildAspectRatio(
                    deviceType,
                    "prod",
                  ),
                ),
                itemBuilder: (context, index) {
                  return ProductCard(product: inStock[index]);
                },
              ),
              if (outOfStock.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Out of Stock / Disabled',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: outOfStock.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: DeviceHelper.getCrossAxisCount(
                      deviceType,
                      false,
                    ),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: DeviceHelper.getChildAspectRatio(
                      deviceType,
                      "prod",
                    ),
                  ),
                  itemBuilder: (context, index) {
                    return ProductCard(product: outOfStock[index]);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// _OrderSummarySheet shows the order summary in a bottom sheet.
class _OrderSummarySheet extends ConsumerStatefulWidget {
  const _OrderSummarySheet({Key? key}) : super(key: key);

  @override
  ConsumerState<_OrderSummarySheet> createState() => _OrderSummarySheetState();
}

class _OrderSummarySheetState extends ConsumerState<_OrderSummarySheet> {
  @override
  void initState() {
    super.initState();
    // Listen to changes in the cart and close the sheet if the cart becomes empty.
    ref.listenManual<List<CartItem>>(cartProvider, (previous, next) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: OrderSummaryPanel(selectedItems: cartItems),
        );
      },
    );
  }
}

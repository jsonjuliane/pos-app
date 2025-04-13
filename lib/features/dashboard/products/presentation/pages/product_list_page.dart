import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/device_helper.dart';
import '../../../../../shared/utils/error_handler.dart';
import '../../../../../shared/widgets/error_message_widget.dart';
import '../../../../../shared/widgets/select_branch_dialog.dart';
import '../../../../auth/presentation/providers/auth_user_providers.dart';
import '../../../../user_management/data/providers/branch_provider.dart';
import '../../../cart/data/models/cart_item.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/order_summary_panel.dart';
import '../../data/models/product.dart';
import '../providers/product_providers.dart';
import '../providers/selected_branch_provider.dart';
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

    // Auto-assign branch for non-owner users
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

    if (user != null && user.role == 'owner' && selectedBranchId == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const SelectBranchDialog(),
            );
          },
          child: const Text('Select Branch'),
        ),
      );
    }

    final cartItems = ref.watch(cartProvider);

    final branchNamesAsync = ref.watch(branchNamesProvider);

    String branchName = 'POS App'; // Default fallback
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
              onRetry: () => ref.refresh(productListProvider),
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
        .where((p) => p.category.toLowerCase() == selectedCategory.toLowerCase())
        .toList();

    final inStockProducts = filtered.where((p) => p.stockCount > 0 && p.enabled).toList();
    final outOfStockProducts = filtered.where((p) => p.stockCount == 0 || !p.enabled).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return isWide
            ? Row(
          children: [
            Expanded(
              flex: 7,
              child: _ProductGrid(
                scrollController: scrollController,
                inStock: inStockProducts,
                outOfStock: outOfStockProducts,
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
            _ProductGrid(
              scrollController: scrollController,
              inStock: inStockProducts,
              outOfStock: outOfStockProducts,
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
        );
      },
    );
  }
}

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategorySelector(products: [...inStock, ...outOfStock]),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: inStock.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: DeviceHelper.getCrossAxisCount(deviceType, false),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: DeviceHelper.getChildAspectRatio(deviceType, "prod"),
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
                      crossAxisCount: DeviceHelper.getCrossAxisCount(deviceType, false),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: DeviceHelper.getChildAspectRatio(deviceType, "prod"),
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
      ),
    );
  }
}

class _OrderSummarySheet extends ConsumerStatefulWidget {
  const _OrderSummarySheet();

  @override
  ConsumerState<_OrderSummarySheet> createState() => _OrderSummarySheetState();
}

class _OrderSummarySheetState extends ConsumerState<_OrderSummarySheet> {
  @override
  void initState() {
    super.initState();

    // Proper listenManual for cart changes
    ref.listenManual<List<CartItem>>(cartProvider, (previous, next) {
      // Only pop when going from non-empty to empty cart
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

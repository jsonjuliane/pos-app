import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/error_handler.dart';
import '../../../../../shared/widgets/error_message_widget.dart';
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
import '../../../../../shared/widgets/select_branch_dialog.dart';

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
          onPressed: branchesAsync.isLoading
              ? null
              : () {
            showDialog(
              context: context,
              builder: (_) => const SelectBranchDialog(),
            );
          },
          child: branchesAsync.isLoading
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
        error: (err, _) => ErrorMessageWidget(
          message: mapFirestoreError(err),
          onRetry: () => ref.refresh(productListProvider),
        ),
        data: (products) => _MainContent(
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
                      child: filtered.isEmpty
                          ? const Center(child: Text('No products available'))
                          : GridView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

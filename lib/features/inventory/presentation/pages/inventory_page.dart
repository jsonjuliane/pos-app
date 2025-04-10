import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../../../../shared/widgets/select_branch_dialog.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';
import '../../../dashboard/products/data/models/product.dart';
import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import '../../../dashboard/products/presentation/widgets/product_card.dart';
import '../../../user_management/data/providers/branch_provider.dart';
import '../../data/providers/inventory_list_provider.dart';
import '../widgets/inventory_product_card.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUserAsync = ref.watch(authUserProvider);
    final selectedBranchId = ref.watch(selectedBranchIdProvider);
    final branchNamesAsync = ref.watch(branchNamesProvider);
    final inventoryListAsync = ref.watch(inventoryListProvider);

    if (authUserAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (authUserAsync.hasError) {
      return ErrorMessageWidget(
        message: mapFirestoreError(authUserAsync.error),
        onRetry: () => ref.refresh(authUserProvider),
      );
    }

    final user = authUserAsync.value!;
    if (user.role != 'owner' &&
        user.branchId != null &&
        selectedBranchId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedBranchIdProvider.notifier).set(user.branchId!);
      });
    }

    String branchName = 'Inventory';
    if (branchNamesAsync is AsyncData && selectedBranchId != null) {
      branchName =
          branchNamesAsync.value?[selectedBranchId] ?? 'Inventory';
    }

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
      body: inventoryListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorMessageWidget(
          message: mapFirestoreError(err),
          onRetry: () => ref.refresh(inventoryListProvider),
        ),
        data: (products) => _InventoryContent(products: products),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Show Add Product Dialog
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}

class _InventoryContent extends StatelessWidget {
  final List<Product> products;

  const _InventoryContent({required this.products});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine grid count based on width
        int crossAxisCount = 2;
        if (constraints.maxWidth >= 1400) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth >= 1100) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 800) {
          crossAxisCount = 3;
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: products.isEmpty
                  ? const Center(child: Text('No products available'))
                  : GridView.builder(
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return InventoryProductCard(
                    product: product,
                    onEdit: () {
                      // TODO: Edit Product
                    },
                    onDelete: () {
                      // TODO: Delete Product
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

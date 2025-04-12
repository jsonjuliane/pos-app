import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/shared/utils/ui_helpers.dart';

import '../../../../shared/utils/device_helper.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../../../../shared/widgets/select_branch_dialog.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';
import '../../../dashboard/products/data/models/product.dart';
import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import '../../../dashboard/products/presentation/providers/selected_category_provider.dart';
import '../../../dashboard/products/presentation/widgets/category_selector.dart';
import '../../../user_management/data/providers/branch_provider.dart';
import '../../data/providers/inventory_list_provider.dart';
import '../../data/providers/inventory_repo_provider.dart';
import '../providers/confirm_delete_dialog.dart';
import '../widgets/add_product_form.dart';
import '../widgets/edit_product_form.dart';
import '../widgets/inventory_product_card.dart';
import '../widgets/manage_category_form.dart';

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
      branchName = branchNamesAsync.value?[selectedBranchId] ?? 'Inventory';
    }

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

    // Default category to all every time the page is refreshed
    ref.listen<String?>(
      selectedBranchIdProvider,
          (previous, next) {
        if (previous != next) {
          ref.read(selectedCategoryProvider.notifier).state = 'All';
        }
      },
    );

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
        error:
            (err, _) => ErrorMessageWidget(
              message: mapFirestoreError(err),
              onRetry: () => ref.refresh(inventoryListProvider),
            ),
        data: (products) => _InventoryContent(products: products),
      ),
      floatingActionButton: user.role == 'owner'
          ? FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Add Product'),
                    onTap: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AddProductForm(
                          onSubmit: (newProduct) async {
                            final selectedBranchId = ref.read(selectedBranchIdProvider);
                            if (selectedBranchId == null) return;
                            try {
                              await ref.read(inventoryRepositoryProvider).addProduct(
                                branchId: selectedBranchId,
                                product: newProduct,
                              );
                              Navigator.of(context).pop();
                            } catch (e) {
                              if (context.mounted) {
                                showErrorSnackBar(context, e.toString());
                              }
                            }
                          },
                          isOwner: true,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('Manage Categories'),
                    onTap: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const ManageCategoryForm(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Manage'),
      )
          : null,
    );
  }
}

class _InventoryContent extends ConsumerWidget {
  final List<Product> products;

  const _InventoryContent({required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    // Filter products based on selected category
    final filteredProducts = (selectedCategory.toLowerCase() == 'all' || selectedCategory.isEmpty)
        ? products
        : products.where((p) => p.category == selectedCategory).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = DeviceHelper.getDeviceType(context);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategorySelector(products: products), // Your existing widget
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? const Center(child: Text('No products available'))
                        : GridView.builder(
                      itemCount: filteredProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: DeviceHelper.getCrossAxisCount(deviceType, true),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: DeviceHelper.getChildAspectRatio(deviceType, true),
                      ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final user = ref.watch(authUserProvider).value!;
                        return InventoryProductCard(
                          product: product,
                          onEdit: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder:
                                  (_) => EditProductForm(
                                initialProduct: product,
                                onSubmit: (updatedProduct) async {
                                  final selectedBranchId = ref.read(
                                    selectedBranchIdProvider,
                                  );
                                  if (selectedBranchId == null) return;

                                  try {
                                    await ref
                                        .read(inventoryRepositoryProvider)
                                        .updateProduct(
                                      branchId: selectedBranchId,
                                      productId: product.id,
                                      product: updatedProduct,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      showErrorSnackBar(
                                        context,
                                        e.toString(),
                                      ); // <- your reusable snackbar utility
                                    }
                                  }

                                  Navigator.of(context).pop();
                                },
                                isOwner:
                                user.role == 'owner', // Pass here
                              ),
                            );
                          },
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (_) => ConfirmDeleteDialog(
                                title: 'Delete Product',
                                message:
                                'Are you sure you want to delete "${product.name}"?',
                                onConfirm: () async {
                                  final selectedBranchId = ref.read(
                                    selectedBranchIdProvider,
                                  );
                                  if (selectedBranchId == null) return;

                                  try {
                                    await ref
                                        .read(inventoryRepositoryProvider)
                                        .deleteProduct(
                                      branchId: selectedBranchId,
                                      productId: product.id,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      showErrorSnackBar(
                                        context,
                                        e.toString(),
                                      ); // <- your reusable snackbar utility
                                    }
                                  }
                                },
                              ),
                            );

                            if (confirm == true) {
                              ref.invalidate(
                                inventoryListProvider,
                              ); // Refresh products
                            }
                          },
                          isOwner: user.role == 'owner',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

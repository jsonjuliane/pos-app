// inventory/presentation/widgets/manage_category_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/ui_helpers.dart';
import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import '../../data/providers/inventory_category_provider.dart';
import '../../data/providers/inventory_repo_provider.dart';

class ManageCategoryForm extends ConsumerStatefulWidget {
  const ManageCategoryForm({super.key});

  @override
  ConsumerState<ManageCategoryForm> createState() => _ManageCategoryFormState();
}

class _ManageCategoryFormState extends ConsumerState<ManageCategoryForm> {
  final _controller = TextEditingController();
  String? _deletingCategoryId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final selectedBranchId = ref.read(selectedBranchIdProvider);
    if (selectedBranchId == null) return;

    try {
      await ref.read(inventoryRepositoryProvider).addCategory(
        branchId: selectedBranchId,
        name: name,
      );
      _controller.clear();
      if (context.mounted) {
        showSuccessSnackBar(context, 'Category added');
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final selectedBranchId = ref.read(selectedBranchIdProvider);
    if (selectedBranchId == null) return;

    setState(() {
      _deletingCategoryId = categoryId;
    });

    try {
      await ref.read(inventoryRepositoryProvider).deleteCategory(
        branchId: selectedBranchId,
        categoryId: categoryId,
      );
      if (context.mounted) {
        showSuccessSnackBar(context, 'Category deleted');
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _deletingCategoryId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(inventoryCategoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(16).add(MediaQuery.of(context).viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage Categories', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'New Category',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addCategory,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Existing Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load categories'),
            data: (categories) => ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category.name),
                  trailing: _deletingCategoryId == category.id
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCategory(category.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

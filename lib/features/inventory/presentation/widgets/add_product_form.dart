import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/inventory/data/model/new_product.dart';
import 'package:pos_app/features/inventory/data/providers/inventory_category_provider.dart';

/// Form to add a new product in Inventory Management.
/// Includes all necessary fields and validation.
class AddProductForm extends ConsumerStatefulWidget {
  final Future<void> Function(NewProduct product) onSubmit;
  final bool isOwner; // NEW

  const AddProductForm({
    super.key,
    required this.onSubmit,
    required this.isOwner,
  });

  @override
  ConsumerState<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends ConsumerState<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _enabled = true;
  bool _isSaving = false; // Track loading state

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true); // Start loading

    final product = NewProduct(
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      stockCount: int.tryParse(_stockController.text.trim()) ?? 0,
      enabled: _enabled,
      imageUrl: null,
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    await widget.onSubmit(product); // Callback from parent
  }

  @override
  Widget build(BuildContext context) {
    final categoryListAsync = ref.watch(inventoryCategoriesProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator:
                  (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            categoryListAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Failed to load categories: $e'),
              data:
                  (categories) => DropdownButtonFormField<String>(
                    value:
                        _categoryController.text.isNotEmpty
                            ? _categoryController.text
                            : null,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items:
                        categories.map((category) {
                          return DropdownMenuItem(
                            value: category.name,
                            child: Text(category.name),
                          );
                        }).toList(),
                    onChanged:
                        widget.isOwner
                            ? (value) {
                              if (value != null) {
                                setState(() {
                                  _categoryController.text = value;
                                });
                              }
                            }
                            : null,
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Required'
                                : null,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock Count'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null)
                  return 'Must be a valid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(_enabled ? 'Enabled' : 'Disabled'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : () {
                FocusScope.of(context).unfocus();
                _submit();
              },
              icon: _isSaving
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Save Product'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/products/data/models/product.dart';
import '../../data/model/new_product.dart';
import '../../data/providers/inventory_category_provider.dart';

class EditProductForm extends ConsumerStatefulWidget {
  final Product initialProduct;
  final Future<void> Function(NewProduct product) onSubmit;
  final bool isOwner; // NEW

  const EditProductForm({
    super.key,
    required this.initialProduct,
    required this.onSubmit,
    required this.isOwner,
  });

  @override
  ConsumerState<EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends ConsumerState<EditProductForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  bool _enabled = true;
  bool _isSaving = false; // Track loading state

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    _nameController = TextEditingController(text: product.name);
    _priceController = TextEditingController(text: product.price.toString());
    _stockController = TextEditingController(
      text: product.stockCount.toString(),
    );
    _categoryController = TextEditingController(text: product.category);
    _descriptionController = TextEditingController(text: product.description);
    _enabled = product.enabled;
  }

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
      imageUrl: widget.initialProduct.imageUrl,
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    await widget.onSubmit(product); // Callback from parent
  }

  @override
  Widget build(BuildContext context) {
    final categoryListAsync = ref.watch(inventoryCategoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).add(MediaQuery.of(context).viewInsets),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              enabled: widget.isOwner,
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
              enabled: widget.isOwner,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              enabled: widget.isOwner,
            ),
            const SizedBox(height: 12),
            categoryListAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Failed to load categories: $e'),
              data:
                  (categories) => DropdownButtonFormField<String>(
                    value:
                        categories.any(
                              (c) => c.name == _categoryController.text,
                            )
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
              label: Text(_isSaving ? 'Updating...' : 'Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}

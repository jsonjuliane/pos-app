import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/inventory/data/model/new_product.dart';
import 'package:pos_app/features/inventory/data/providers/inventory_category_provider.dart';

import '../../../dashboard/products/data/models/product.dart';

/// Product creation form supporting multiple named price variants.
/// Designed with scalability and UX in mind.
class AddProductForm extends ConsumerStatefulWidget {
  final Future<void> Function(NewProduct product) onSubmit;
  final bool isOwner;

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
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<TextEditingController> _variantNameControllers = [TextEditingController()];
  final List<TextEditingController> _variantPriceControllers = [TextEditingController()];

  bool _enabled = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    for (final c in _variantNameControllers) c.dispose();
    for (final c in _variantPriceControllers) c.dispose();
    super.dispose();
  }

  void _addPriceVariantField() {
    setState(() {
      _variantNameControllers.add(TextEditingController());
      _variantPriceControllers.add(TextEditingController());
    });
  }

  void _removePriceVariantField(int index) {
    if (_variantNameControllers.length <= 1) return;
    setState(() {
      _variantNameControllers[index].dispose();
      _variantPriceControllers[index].dispose();
      _variantNameControllers.removeAt(index);
      _variantPriceControllers.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSaving = true);

    final prices = <PriceVariant>[];
    for (int i = 0; i < _variantNameControllers.length; i++) {
      final name = _variantNameControllers[i].text.trim();
      final priceText = _variantPriceControllers[i].text.trim();
      final price = double.tryParse(priceText);
      if (name.isNotEmpty && price != null && price > 0) {
        prices.add(PriceVariant(name: name, price: price));
      }
    }

    final product = NewProduct(
      name: _nameController.text.trim(),
      prices: prices,
      stockCount: int.tryParse(_stockController.text.trim()) ?? 0,
      enabled: _enabled,
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: null,
    );

    await widget.onSubmit(product);
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
            // Product Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            // Price Variants
            Text('Prices', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _variantNameControllers.length,
              itemBuilder: (context, index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _variantNameControllers[index],
                        decoration: const InputDecoration(labelText: 'Variant Name'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _variantPriceControllers[index],
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    if (_variantNameControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removePriceVariantField(index),
                      ),
                  ],
                );
              },
            ),
            TextButton.icon(
              onPressed: _addPriceVariantField,
              icon: const Icon(Icons.add),
              label: const Text('Add Variant'),
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            categoryListAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Failed to load categories: $e'),
              data: (categories) => DropdownButtonFormField<String>(
                value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: widget.isOwner ? (v) => _categoryController.text = v! : null,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),

            const SizedBox(height: 16),

            // Stock Count
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock Count'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (int.tryParse(v) == null) return 'Invalid';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Enabled Toggle
            SwitchListTile(
              title: Text(_enabled ? 'Enabled' : 'Disabled'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : () {
                FocusScope.of(context).unfocus();
                _submit();
              },
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Save Product'),
            ),
          ],
        ),
      ),
    );
  }
}

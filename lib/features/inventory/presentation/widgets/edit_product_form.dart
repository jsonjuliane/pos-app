import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/products/data/models/product.dart';
import '../../data/model/new_product.dart';
import '../../data/providers/inventory_category_provider.dart';

/// Form to edit an existing product.
/// Clean, scalable, senior-level implementation.
class EditProductForm extends ConsumerStatefulWidget {
  final Product initialProduct;
  final Future<void> Function(NewProduct product) onSubmit;
  final bool isOwner;

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
  late final TextEditingController _stockController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;

  late List<TextEditingController> _priceNameControllers;
  late List<TextEditingController> _priceValueControllers;

  bool _enabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;

    _nameController = TextEditingController(text: p.name);
    _stockController = TextEditingController();
    _categoryController = TextEditingController(text: p.category);
    _descriptionController = TextEditingController(text: p.description);

    _enabled = p.enabled;

    _priceNameControllers = p.prices
        .map((e) => TextEditingController(text: e.name))
        .toList();

    _priceValueControllers = p.prices
        .map((e) => TextEditingController(text: e.price.toString()))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    for (final c in _priceNameControllers) {
      c.dispose();
    }
    for (final c in _priceValueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final addedStock = int.tryParse(_stockController.text.trim()) ?? 0;

    final prices = List.generate(
      _priceNameControllers.length,
          (i) => PriceVariant(
        name: _priceNameControllers[i].text.trim(),
        price: double.tryParse(_priceValueControllers[i].text.trim()) ?? 0,
      ),
    );

    final product = NewProduct(
      name: _nameController.text.trim(),
      prices: prices,
      stockCount: widget.initialProduct.stockCount + addedStock,
      enabled: _enabled,
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: widget.initialProduct.imageUrl,
    );

    await widget.onSubmit(product);
  }

  void _addPriceVariant() {
    setState(() {
      _priceNameControllers.add(TextEditingController());
      _priceValueControllers.add(TextEditingController());
    });
  }

  void _removePriceVariant(int index) {
    if (_priceNameControllers.length <= 1) return;
    setState(() {
      _priceNameControllers[index].dispose();
      _priceValueControllers[index].dispose();
      _priceNameControllers.removeAt(index);
      _priceValueControllers.removeAt(index);
    });
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
            /// Product Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              enabled: widget.isOwner,
            ),
            const SizedBox(height: 12),

            /// Price Variants
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Prices',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),

            ..._priceNameControllers.asMap().entries.map((entry) {
              final index = entry.key;
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceNameControllers[index],
                      decoration: const InputDecoration(labelText: 'Label'),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                      enabled: widget.isOwner,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceValueControllers[index],
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (v) =>
                      (v == null || double.tryParse(v) == null)
                          ? 'Invalid'
                          : null,
                      enabled: widget.isOwner,
                    ),
                  ),
                  if (_priceNameControllers.length > 1 && widget.isOwner)
                    IconButton(
                      icon:
                      const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removePriceVariant(index),
                    ),
                ],
              );
            }),

            if (widget.isOwner)
              TextButton.icon(
                onPressed: _addPriceVariant,
                icon: const Icon(Icons.add),
                label: const Text('Add Price Variant'),
              ),
            const SizedBox(height: 12),

            /// Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              enabled: widget.isOwner,
            ),
            const SizedBox(height: 12),

            /// Category
            categoryListAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Failed to load categories: $e'),
              data: (categories) => DropdownButtonFormField<String>(
                value: _categoryController.text.isNotEmpty
                    ? _categoryController.text
                    : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((c) =>
                    DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged:
                widget.isOwner ? (v) => _categoryController.text = v! : null,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 12),

            /// Add Stock Field
            /// Add Stock Field
            TextFormField(
              controller: _stockController,
              decoration: InputDecoration(
                labelText: 'Add Stock',
                helperText: 'Current Stock: ${widget.initialProduct.stockCount}',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return null; // Optional
                final addedStock = int.tryParse(v);
                if (addedStock == null) return 'Invalid number';
                if (addedStock < 0) return 'Cannot decrease stock';
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
              onPressed: _isSaving
                  ? null
                  : () {
                FocusScope.of(context).unfocus();
                _submit();
              },
              icon: _isSaving
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Updating...' : 'Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}
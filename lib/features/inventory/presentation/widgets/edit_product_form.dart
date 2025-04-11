import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model/new_product.dart';
import '../../../dashboard/products/data/models/product.dart';
import '../../data/providers/inventory_category_provider.dart';

class EditProductForm extends ConsumerStatefulWidget {
  final Product initialProduct;
  final void Function(NewProduct product) onSubmit;
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

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    _nameController = TextEditingController(text: product.name);
    _priceController = TextEditingController(text: product.price.toString());
    _stockController = TextEditingController(text: product.stockCount.toString());
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

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final product = NewProduct(
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      stockCount: int.tryParse(_stockController.text.trim()) ?? 0,
      enabled: _enabled,
      imageUrl: widget.initialProduct.imageUrl,
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    widget.onSubmit(product);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(inventoryCategoriesProvider);

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
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
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
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Failed to load categories'),
              data: (categories) => Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return categories;
                  }
                  return categories.where((c) =>
                      c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  if (controller.text.isEmpty && _categoryController.text.isNotEmpty) {
                    controller.text = _categoryController.text;
                  }

                  controller.addListener(() {
                    if (controller.text != _categoryController.text) {
                      _categoryController.text = controller.text;
                    }
                  });

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    enabled: widget.isOwner,
                  );
                },
                onSelected: (value) {
                  _categoryController.text = value;
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(option),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
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
                if (int.tryParse(value) == null) return 'Must be a valid number';
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
              onPressed: () {
                FocusScope.of(context).unfocus();
                _submit();
              },
              icon: const Icon(Icons.save),
              label: const Text('Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}

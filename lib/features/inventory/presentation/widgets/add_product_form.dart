import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/inventory/data/model/new_product.dart';
import 'package:pos_app/features/inventory/data/providers/inventory_category_provider.dart';

/// Form to add a new product in Inventory Management.
/// Includes all necessary fields and validation.
class AddProductForm extends ConsumerStatefulWidget {
  final void Function(NewProduct product) onSubmit;

  const AddProductForm({super.key, required this.onSubmit});

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
      imageUrl: null, // Optional, for future image upload
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    widget.onSubmit(product);
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
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
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
              data: (categories) => Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return categories;
                  }
                  return categories.where((category) =>
                      category.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  controller.text = _categoryController.text;

                  controller.addListener(() {
                    // Keep _categoryController in sync
                    _categoryController.text = controller.text;
                  });

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
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
                          itemCount: options.length,
                          shrinkWrap: true,
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
            const SizedBox(height: 12),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus(); // Dismiss keyboard
                _submit(); // Validate & submit
              },
              icon: const Icon(Icons.check),
              label: const Text('Save Product'),
            ),
          ],
        ),
      ),
    );
  }
}
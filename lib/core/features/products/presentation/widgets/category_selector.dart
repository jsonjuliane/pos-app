import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/utils/string_extensions.dart';

import '../../data/models/product.dart';
import '../../data/providers/category_provider.dart';

/// Builds a scrollable list of category chips based on products.
class CategorySelector extends ConsumerWidget {
  final List<Product> products;

  const CategorySelector({super.key, required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);

    // Derive unique category list from products + "All"
    final categories = <String>{'All'};
    categories.addAll(products.map((p) => p.category).toSet());

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            categories.map((category) {
              final isSelected = selected == category;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category.capitalize()),
                  selected: isSelected,
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[700],
                  ),
                  onSelected: (_) {
                    ref.read(selectedCategoryProvider.notifier).state =
                        category;
                  },
                ),
              );
            }).toList(),
      ),
    );
  }
}

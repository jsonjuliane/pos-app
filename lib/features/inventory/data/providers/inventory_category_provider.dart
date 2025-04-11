// inventory_category_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import 'inventory_repo_provider.dart';

final inventoryCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final branchId = ref.watch(selectedBranchIdProvider);
  if (branchId == null) return [];
  final repo = ref.read(inventoryRepositoryProvider);
  final products = await repo.getProducts(branchId: branchId).first;
  return products.map((p) => p.category).toSet().toList();
});

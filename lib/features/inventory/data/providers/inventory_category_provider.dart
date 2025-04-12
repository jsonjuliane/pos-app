// inventory_category_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import '../model/category.dart';
import 'inventory_repo_provider.dart';

final inventoryCategoriesProvider = StreamProvider.autoDispose<List<Category>>((ref) {
  final branchId = ref.watch(selectedBranchIdProvider);
  if (branchId == null) return const Stream.empty();
  return ref.watch(inventoryRepositoryProvider).getCategories(branchId: branchId);
});

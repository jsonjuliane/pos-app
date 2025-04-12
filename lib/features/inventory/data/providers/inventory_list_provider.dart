import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/products/data/models/product.dart';
import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import 'inventory_repo_provider.dart';

/// Provides product list for Inventory Management.
final inventoryListProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final branchId = ref.watch(selectedBranchIdProvider);

  if (branchId == null || branchId.isEmpty) {
    return const Stream.empty();
  }

  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getProducts(branchId: branchId);
});
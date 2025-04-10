import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/dashboard/products/presentation/providers/selected_branch_provider.dart';
import '../../../../auth/presentation/providers/auth_user_providers.dart';
import '../../data/models/product.dart';
import '../../data/providers/product_repo_providers.dart';

/// Provides the live list of products to the UI as a stream.
final productListProvider = StreamProvider<List<Product>>((ref) {
  final user = ref.watch(authUserProvider).value;
  final selectedBranchId = ref.watch(selectedBranchIdProvider);

  if (user == null) return Stream.value([]);

  final isOwner = user.role == 'owner';

  if (isOwner) {
    // Owner must manually select a branch
    if (selectedBranchId == null || selectedBranchId.isEmpty) {
      return Stream.value([]);
    }
    final repo = ref.read(productRepoProvider);
    return repo.getProducts(branchId: selectedBranchId);
  }

  // For admin/staff, use their assigned branch
  final branchId = user.branchId;
  if (branchId == null || branchId.isEmpty) {
    return Stream.value([]);
  }

  final repo = ref.read(productRepoProvider);
  return repo.getProducts(branchId: branchId);
});
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import '../models/product_order.dart';
import 'order_repo_providers.dart';

final orderListProvider = StreamProvider.autoDispose<List<ProductOrder>>((ref) {
  final branchId = ref.watch(selectedBranchIdProvider);
  if (branchId == null) return Stream.value([]);
  return ref.read(orderRepoProvider).getOrders(branchId);
});
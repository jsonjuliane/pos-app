import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import '../model/inventory_report.dart';
import 'report_repo_providers.dart';

final inventoryReportListProvider = StreamProvider.autoDispose<List<InventoryReport>>((ref) {
  final branchId = ref.watch(selectedBranchIdProvider);
  if (branchId == null) return Stream.value([]);
  return ref.read(reportRepoProvider).getReports(branchId);
});
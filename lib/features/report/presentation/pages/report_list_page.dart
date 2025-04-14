import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/report/data/model/inventory_report.dart';
import 'package:pos_app/features/report/data/providers/report_repo_providers.dart';
import 'package:pos_app/features/dashboard/products/presentation/providers/selected_branch_provider.dart';
import 'package:pos_app/features/auth/presentation/providers/auth_user_providers.dart';
import 'package:pos_app/features/user_management/data/providers/branch_provider.dart';
import 'package:pos_app/shared/widgets/error_message_widget.dart';
import 'package:pos_app/shared/widgets/select_branch_dialog.dart';
import 'package:pos_app/shared/utils/device_helper.dart';
import 'package:pos_app/shared/utils/error_handler.dart';
import 'package:pos_app/features/inventory/presentation/widgets/inventory_report_card.dart';
import 'report_detail_page.dart';

/// Enum for filtering reports based on time period.
enum ReportFilter { week, month, year }

/// ReportListPage displays InventoryReports with a time filter (Week/Month/Year).
class ReportListPage extends ConsumerStatefulWidget {
  const ReportListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends ConsumerState<ReportListPage> {
  ReportFilter _selectedFilter = ReportFilter.week;

  /// Computes the threshold DateTime based on the selected filter.
  DateTime _computeThreshold() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case ReportFilter.week:
      // Assuming week starts on Monday.
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      case ReportFilter.month:
        return DateTime(now.year, now.month, 1);
      case ReportFilter.year:
        return DateTime(now.year, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(selectedBranchIdProvider);
    final authUserAsync = ref.watch(authUserProvider);
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    if (authUserAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (authUserAsync.hasError) {
      return ErrorMessageWidget(
        message: mapFirestoreError(authUserAsync.error),
        onRetry: () => ref.refresh(authUserProvider),
      );
    }
    final user = authUserAsync.value!;

    // Auto-assign branch for non-owner users.
    if (user.role != 'owner' &&
        user.branchId != null &&
        selectedBranchId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedBranchIdProvider.notifier).set(user.branchId!);
      });
    }
    // For owners without a selected branch, show branch selector.
    if (user.role == 'owner' && selectedBranchId == null) {
      final branchesAsync = ref.watch(allBranchesProvider);
      return Center(
        child: ElevatedButton(
          onPressed: branchesAsync.isLoading
              ? null
              : () {
            showDialog(
              context: context,
              builder: (_) => const SelectBranchDialog(),
            );
          },
          child: branchesAsync.isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Select Branch'),
        ),
      );
    }
    if (branchId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Retrieve the stream of reports.
    final reportsStream = ref.watch(reportRepoProvider).getReports(branchId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          if (user.role == 'owner')
            IconButton(
              tooltip: 'Change Branch',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SelectBranchDialog(),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<List<InventoryReport>>(
        stream: reportsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reports.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Apply time filter to the reports.
          final allReports = snapshot.data!;
          final threshold = _computeThreshold();
          final filteredReports = allReports.where((report) => report.date.isAfter(threshold)).toList();

          final deviceType = DeviceHelper.getDeviceType(context);

          return filteredReports.isEmpty
              ? const Center(child: Text('No reports available'))
              : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Time Filter Choice Chips.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ReportFilter.values.map((filter) {
                    final label = filter.toString().split('.').last.toUpperCase();
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: filteredReports.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: DeviceHelper.getCrossAxisCount(deviceType, true),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: DeviceHelper.getChildAspectRatio(deviceType, "rep"),
                    ),
                    itemBuilder: (context, index) {
                      return InventoryReportCard(
                        report: filteredReports[index],
                        onTap: () async {
                          // Fetch products once.
                          final products = await ref.read(reportRepoProvider).getProductsOnce(branchId: branchId);
                          final productMap = {for (var p in products) p.id: p};
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportDetailPage(
                                report: filteredReports[index],
                                productMap: productMap,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
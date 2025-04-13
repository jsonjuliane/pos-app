import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/report/data/providers/report_repo_providers.dart';

import '../../../../../shared/utils/device_helper.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';
import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import '../../../inventory/presentation/widgets/inventory_report_card.dart';
import '../../data/model/inventory_report.dart';
import 'report_detail_page.dart';

class ReportListPage extends ConsumerWidget {
  const ReportListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(selectedBranchIdProvider);
    final userAsync = ref.watch(authUserProvider);

    if (branchId == null || userAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final reportsStream = ref
        .watch(reportRepoProvider)
        .getReports(branchId);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: StreamBuilder<List<InventoryReport>>(
        stream: reportsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reports.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!;
          final deviceType = DeviceHelper.getDeviceType(context);

          return reports.isEmpty
              ? const Center(child: Text('No reports available'))
              : Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: reports.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                DeviceHelper.getCrossAxisCount(deviceType, true),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio:
                DeviceHelper.getChildAspectRatio(deviceType, "rep"),
              ),
              itemBuilder: (context, index) {
                return InventoryReportCard(
                  report: reports[index],
                  onTap: () async {
                    // Fetch products once
                    final products = await ref
                        .read(reportRepoProvider)
                        .getProductsOnce(branchId: branchId); // Add this in your repo if not yet

                    final productMap = {for (var p in products) p.id: p};

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportDetailPage(
                              report: reports[index],
                              productMap: productMap,
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
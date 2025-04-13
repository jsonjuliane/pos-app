import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/report/data/providers/report_repo_providers.dart';

import '../../../../../shared/utils/device_helper.dart';
import '../../../../../shared/utils/ui_helpers.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';
import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import 'report_detail_page.dart';
import '../../../inventory/presentation/widgets/inventory_report_card.dart';
import '../../data/model/inventory_report.dart';

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
                DeviceHelper.getChildAspectRatio(deviceType, "ord"),
              ),
              itemBuilder: (context, index) {
                return InventoryReportCard(
                  report: reports[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportDetailPage(
                              report: reports[index],
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
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_chart),
        label: const Text('Generate Report'),
        onPressed: () async {
          await _handleGenerateReport(context, ref, branchId);
        },
      ),
    );
  }

  Future<void> _handleGenerateReport(
      BuildContext context, WidgetRef ref, String branchId) async {

    final repo = ref.read(reportRepoProvider);

    // Show initial loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final now = DateTime.now();
      final existingReport = await repo.getReportByDate(
        branchId: branchId,
        date: DateTime(now.year, now.month, now.day),
      );

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      // Ask for overwrite confirmation if report already exists
      if (existingReport != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Overwrite Report?'),
            content: const Text('Report for today already exists. Overwrite?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                child: const Text('Overwrite'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }

      // Show loading again for report generation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await repo.generateReport(branchId: branchId);

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      showSuccessSnackBar(context, 'Report generated!');
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      showErrorSnackBar(context, 'Failed to generate report.');
    }
  }
}
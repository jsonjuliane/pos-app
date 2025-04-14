import 'package:flutter/material.dart';
import '../../../report/data/model/inventory_report.dart';

class InventoryReportCard extends StatelessWidget {
  final InventoryReport report;
  final VoidCallback onTap;

  const InventoryReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${report.date.toLocal().toString().split(' ')[0]}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text('Products Tracked: ${report.startInventory.length}'),
              Text('Created: ${report.createdAt.toLocal()}',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
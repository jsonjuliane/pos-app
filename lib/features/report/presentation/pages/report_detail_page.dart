import 'package:flutter/material.dart';
import '../../../dashboard/products/data/models/product.dart';
import '../../data/model/inventory_report.dart';

class ReportDetailPage extends StatelessWidget {
  final InventoryReport report;
  final Map<String, Product> productMap;

  const ReportDetailPage({
    super.key,
    required this.report,
    required this.productMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Date: ${report.date.toLocal().toString().split(' ')[0]}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _infoRow('Created At:', report.createdAt.toLocal().toString()),
            _infoRow('Updated At:', report.updatedAt.toLocal().toString()),
            const SizedBox(height: 16),

            Text(
              'Inventory Breakdown:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...report.startInventory.keys.map((productId) {
              final start = report.startInventory[productId] ?? 0;
              final added = report.addedInventory[productId] ?? 0;
              final sold = report.soldInventory[productId] ?? 0;
              final end = report.endInventory[productId] ?? 0;
              final productName = productMap[productId]?.name ?? 'Unknown Product';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(productName), // Product Name here
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _columnValue('Start', start),
                      _columnValue('Add', added),
                      _columnValue('Sold', sold),
                      _columnValue('End', end),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  Widget _columnValue(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
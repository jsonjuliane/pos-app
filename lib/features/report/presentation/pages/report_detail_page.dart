import 'dart:typed_data'; // Correct import for Uint8List

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../dashboard/products/data/models/product.dart';
import '../../data/model/inventory_report.dart';
import '../../data/model/sales_summary.dart';
import '../../data/providers/report_repo_providers.dart';

class ReportDetailPage extends ConsumerWidget {
  final InventoryReport report;
  final Map<String, Product> productMap;

  const ReportDetailPage({
    super.key,
    required this.report,
    required this.productMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('yyyy-MM-dd hh:mm a'); // e.g. 2025-04-14 03:45 PM

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final salesSummary = await ref
                  .read(reportRepoProvider)
                  .getSalesSummary(
                    branchId: report.branchId,
                    date: report.date,
                  );

              await Printing.layoutPdf(
                onLayout: (format) => _generatePdf(report, salesSummary),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Date: ${report.date.toLocal().toString().split(' ')[0]}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _infoRow('Created At:', dateFormatter.format(report.createdAt.toLocal())),
            _infoRow('Updated At:', dateFormatter.format(report.updatedAt.toLocal())),
            const SizedBox(height: 16),

            Text(
              'Inventory Breakdown:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ...report.startInventory.keys.map((productId) {
              final start = report.startInventory[productId] ?? 0;
              final added = report.addedInventory[productId] ?? 0;
              final sold = report.soldInventory[productId] ?? 0;
              final end = report.endInventory[productId] ?? 0;
              final productName =
                  productMap[productId]?.name ?? 'Unknown Product';

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
      child: Row(children: [Expanded(child: Text(label)), Text(value)]),
    );
  }

  Widget _columnValue(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<Uint8List> _generatePdf(
      InventoryReport report,
      SalesSummary summary,
      ) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('yyyy-MM-dd hh:mm a');

    // Group items by (name + price)
    final groupedItems = <String, Map<String, dynamic>>{};

    for (final item in summary.items) {
      final key = '${item.name}-${item.price}';
      if (groupedItems.containsKey(key)) {
        groupedItems[key]!['quantity'] += item.quantity;
        groupedItems[key]!['subtotal'] += item.subtotal;
        groupedItems[key]!['discount'] += item.discount;
      } else {
        groupedItems[key] = {
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
          'discount': item.discount,
        };
      }
    }

    final totalSubtotal = groupedItems.values
        .fold<double>(0, (sum, item) => sum + item['subtotal']);
    final totalDiscount = groupedItems.values
        .fold<double>(0, (sum, item) => sum + item['discount']);
    final totalFinal = totalSubtotal - totalDiscount;

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Inventory Report - ${report.date.toLocal().toString().split(' ')[0]}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          pw.Text('Created At: ${dateFormatter.format(report.createdAt.toLocal())}'),
          pw.Text('Updated At: ${dateFormatter.format(report.updatedAt.toLocal())}'),

          pw.SizedBox(height: 16),
          pw.Text('Inventory Breakdown:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            headers: ['Product', 'Start', 'Add', 'Sold', 'End'],
            data: report.startInventory.keys.map((productId) {
              final name = productMap[productId]?.name ?? 'Unknown';
              return [
                name,
                '${report.startInventory[productId] ?? 0}',
                '${report.addedInventory[productId] ?? 0}',
                '${report.soldInventory[productId] ?? 0}',
                '${report.endInventory[productId] ?? 0}',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 16),
          pw.Text('Itemized Sales:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            headers: ['Item', 'Price', 'Qty', 'Subtotal', 'Discount', 'Total'],
            data: groupedItems.values.map((item) {
              final total = item['subtotal'] - item['discount'];
              return [
                item['name'],
                'P${item['price'].toStringAsFixed(2)}',
                '${item['quantity']}',
                'P${item['subtotal'].toStringAsFixed(2)}',
                'P${item['discount'].toStringAsFixed(2)}',
                'P${total.toStringAsFixed(2)}',
              ];
            }).toList()
              ..add([
                'TOTAL',
                '',
                '',
                'P${totalSubtotal.toStringAsFixed(2)}',
                'P${totalDiscount.toStringAsFixed(2)}',
                'P${totalFinal.toStringAsFixed(2)}',
              ]),
          ),

          pw.SizedBox(height: 16),

          pw.Text('Sales Summary:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.Table(
            columnWidths: {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              _summaryRow('Items Sold:', '${summary.totalItemsSold} pcs'),
              _summaryRow('Gross Sales:', 'P${summary.grossSales.toStringAsFixed(2)}'),
              _summaryRow('Total Discount:', 'P${summary.totalDiscount.toStringAsFixed(2)}'),
              pw.TableRow(children: [
                pw.Container(
                  color: PdfColors.grey300,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: pw.Text('Net Sales:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  color: PdfColors.grey300,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: pw.Text(
                    'P${summary.netSales.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ]),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.TableRow _summaryRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(label),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(value, textAlign: pw.TextAlign.right),
      ),
    ]);
  }

}

import 'dart:typed_data';

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
    final dateFormatter = DateFormat('yyyy-MM-dd hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final summary = await ref.read(reportRepoProvider).getSalesSummary(
                branchId: report.branchId,
                date: report.date,
              );
              await Printing.layoutPdf(
                onLayout: (format) => _generatePdf(report, summary),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<SalesSummary>(
        future: ref.read(reportRepoProvider).getSalesSummary(
          branchId: report.branchId,
          date: report.date,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final summary = snapshot.data!;
          final groupedItems = _groupSalesItems(summary.items);
          final totalSubtotal = groupedItems.fold<double>(0, (sum, item) => sum + item['subtotal']);
          final totalDiscount = groupedItems.fold<double>(0, (sum, item) => sum + item['discount']);
          final totalFinal = totalSubtotal - totalDiscount;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Report - ${DateFormat('yyyy-MM-dd').format(report.date)}',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _infoRow('Created At:', dateFormatter.format(report.createdAt.toLocal())),
              _infoRow('Updated At:', dateFormatter.format(report.updatedAt.toLocal())),

              const SizedBox(height: 20),
              Text('Breakdown', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildInventoryTable(theme),

              const SizedBox(height: 24),
              Text('Itemized Sales', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildSalesTable(theme, groupedItems, totalSubtotal, totalDiscount, totalFinal),

              const SizedBox(height: 24),
              Text('Sales Summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _summaryRow('Items Sold:', '${summary.totalItemsSold} pcs'),
              _summaryRow('Gross Sales:', '₱${summary.grossSales.toStringAsFixed(2)}'),
              _summaryRow('Total Discount:', '₱${summary.totalDiscount.toStringAsFixed(2)}'),
              _summaryRow('Net Sales:', '₱${summary.netSales.toStringAsFixed(2)}', bold: true, highlight: true),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupSalesItems(List items) {
    final grouped = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final key = '${item.name}-${item.price}';
      if (grouped.containsKey(key)) {
        grouped[key]!['quantity'] += item.quantity;
        grouped[key]!['subtotal'] += item.subtotal;
        grouped[key]!['discount'] += item.discount;
      } else {
        grouped[key] = {
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
          'discount': item.discount,
        };
      }
    }
    return grouped.values.toList();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.black87))),
        Text(value),
      ]),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, bool highlight = false}) {
    return Container(
      color: highlight ? Colors.grey.shade200 : null,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  Widget _buildInventoryTable(ThemeData theme) {
    final headers = ['Product', 'Start', 'Add', 'Sold', 'End'];
    final rows = report.startInventory.keys.map((productId) {
      final name = productMap[productId]?.name ?? 'Unknown';
      return [
        name,
        '${report.startInventory[productId] ?? 0}',
        '${report.addedInventory[productId] ?? 0}',
        '${report.soldInventory[productId] ?? 0}',
        '${report.endInventory[productId] ?? 0}',
      ];
    }).toList();

    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
      columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
      rows: rows.map((r) => DataRow(cells: r.map((c) => DataCell(Text(c))).toList())).toList(),
    );
  }

  Widget _buildSalesTable(ThemeData theme, List<Map<String, dynamic>> items, double subtotal, double discount, double total) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
      columns: const [
        DataColumn(label: Text('Item')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Qty')),
        DataColumn(label: Text('Subtotal')),
        DataColumn(label: Text('Discount')),
        DataColumn(label: Text('Total')),
      ],
      rows: [
        ...items.map((item) => DataRow(cells: [
          DataCell(Text(item['name'])),
          DataCell(Text('₱${item['price'].toStringAsFixed(2)}')),
          DataCell(Text('${item['quantity']}')),
          DataCell(Text('₱${item['subtotal'].toStringAsFixed(2)}')),
          DataCell(Text('₱${item['discount'].toStringAsFixed(2)}')),
          DataCell(Text('₱${(item['subtotal'] - item['discount']).toStringAsFixed(2)}')),
        ])),
        DataRow(
          color: MaterialStateProperty.all(Colors.grey.shade100),
          cells: [
            DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataCell(Text('')),
            const DataCell(Text('')),
            DataCell(Text('₱${subtotal.toStringAsFixed(2)}')),
            DataCell(Text('₱${discount.toStringAsFixed(2)}')),
            DataCell(Text('₱${total.toStringAsFixed(2)}')),
          ],
        ),
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

    final totalSubtotal = groupedItems.values.fold<double>(0, (sum, item) => sum + item['subtotal']);
    final totalDiscount = groupedItems.values.fold<double>(0, (sum, item) => sum + item['discount']);
    final totalFinal = totalSubtotal - totalDiscount;

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Report - ${DateFormat('yyyy-MM-dd').format(report.date)}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          pw.Text('Created At: ${dateFormatter.format(report.createdAt.toLocal())}'),
          pw.Text('Updated At: ${dateFormatter.format(report.updatedAt.toLocal())}'),

          pw.SizedBox(height: 16),
          pw.Text('Breakdown:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
              _tableSummaryRow('Items Sold:', '${summary.totalItemsSold} pcs'),
              _tableSummaryRow('Gross Sales:', 'P${summary.grossSales.toStringAsFixed(2)}'),
              _tableSummaryRow('Total Discount:', 'P${summary.totalDiscount.toStringAsFixed(2)}'),
              pw.TableRow(
                children: [
                  pw.Container(
                    color: PdfColors.grey300,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Net Sales:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    color: PdfColors.grey300,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'P${summary.netSales.toStringAsFixed(2)}',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.TableRow _tableSummaryRow(String label, String value, {bool bold = false, bool highlight = false}) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    final containerStyle = highlight
        ? pw.BoxDecoration(color: PdfColors.grey300)
        : null;

    return pw.TableRow(
      children: [
        pw.Container(
          decoration: containerStyle,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label, style: style),
        ),
        pw.Container(
          decoration: containerStyle,
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(value, style: style),
        ),
      ],
    );
  }

// Your existing _generatePdf implementation with grouping logic stays as-is
}

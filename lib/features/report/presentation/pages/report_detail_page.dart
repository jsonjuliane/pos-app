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

/// ReportDetailPage displays the detailed report with dynamic filtering by included product categories.
/// The same filtering is applied to the generated PDF.
class ReportDetailPage extends ConsumerStatefulWidget {
  final InventoryReport report;
  final Map<String, Product> productMap;

  const ReportDetailPage({
    super.key,
    required this.report,
    required this.productMap,
  });

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  late Set<String> _includedCategories;

  @override
  void initState() {
    super.initState();
    // By default, include all available categories from the productMap.
    _includedCategories = widget.productMap.values.map((p) => p.category).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('yyyy-MM-dd hh:mm a');

    // Get all unique categories from productMap.
    final allCategories = widget.productMap.values.map((p) => p.category).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final summary = await ref.read(reportRepoProvider).getSalesSummary(
                branchId: widget.report.branchId,
                date: widget.report.date,
              );
              await Printing.layoutPdf(
                onLayout: (format) => _generatePdf(
                  widget.report,
                  summary,
                  includedCategories: _includedCategories,
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<SalesSummary>(
        future: ref.read(reportRepoProvider).getSalesSummary(
          branchId: widget.report.branchId,
          date: widget.report.date,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final summary = snapshot.data!;

          // Filter sales items based on included categories.
          final filteredSalesItems = summary.items.where((item) {
            final prod = widget.productMap[item.productId];
            return prod != null && _includedCategories.contains(prod.category);
          }).toList();

          // Group the filtered sales items using the same logic.
          final groupedItems = _groupSalesItems(filteredSalesItems);
          final totalSubtotal = groupedItems.fold<double>(0, (sum, item) => sum + item['subtotal']);
          final totalDiscount = groupedItems.fold<double>(0, (sum, item) => sum + item['discount']);
          final totalFinal = totalSubtotal - totalDiscount;

          // Recalculate summary from filtered items.
          final totalItemsSold = filteredSalesItems.fold<int>(0, (sum, item) => sum + item.quantity);
          final grossSales = filteredSalesItems.fold<double>(0, (sum, item) => sum + item.subtotal);
          final totalDiscountAgg = filteredSalesItems.fold<double>(0, (sum, item) => sum + item.discount);
          final netSales = grossSales - totalDiscountAgg;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Report Header
              Text(
                'Report - ${DateFormat('yyyy-MM-dd').format(widget.report.date)}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _infoRow('Created At:', dateFormatter.format(widget.report.createdAt.toLocal())),
              _infoRow('Updated At:', dateFormatter.format(widget.report.updatedAt.toLocal())),
              const SizedBox(height: 16),

              // Included Categories Filter
              Text('Included Categories', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: allCategories.map((category) {
                  final isSelected = _includedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _includedCategories.add(category);
                        } else {
                          _includedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Inventory Breakdown Section
              Text('Breakdown', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildInventoryTable(theme),

              const SizedBox(height: 24),

              // Itemized Sales Section
              Text('Itemized Sales', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildSalesTable(theme, groupedItems, totalSubtotal, totalDiscount, totalFinal),

              const SizedBox(height: 24),

              // Sales Summary Section
              Text('Sales Summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _summaryRow('Items Sold:', '${totalItemsSold} pcs'),
              _summaryRow('Gross Sales:', '₱${grossSales.toStringAsFixed(2)}'),
              _summaryRow('Total Discount:', '₱${totalDiscountAgg.toStringAsFixed(2)}'),
              _summaryRow('Net Sales:', '₱${netSales.toStringAsFixed(2)}', bold: true, highlight: true),
            ],
          );
        },
      ),
    );
  }

  /// Groups sales items by (name + price).
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

  /// Builds a simple info row for label and value.
  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75)),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// Builds the Inventory Breakdown table filtered by included categories.
  Widget _buildInventoryTable(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final headers = ['Product', 'Start', 'Add', 'Sold', 'End'];
    final rows = widget.report.startInventory.keys.where((productId) {
      final product = widget.productMap[productId];
      return product != null && _includedCategories.contains(product.category);
    }).map((productId) {
      final name = widget.productMap[productId]?.name ?? 'Unknown';
      return [
        name,
        '${widget.report.startInventory[productId] ?? 0}',
        '${widget.report.addedInventory[productId] ?? 0}',
        '${widget.report.soldInventory[productId] ?? 0}',
        '${widget.report.endInventory[productId] ?? 0}',
      ];
    }).toList();

    return DataTable(
      headingRowColor: MaterialStateProperty.all(colorScheme.surfaceVariant),
      columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
      rows: rows.map((r) => DataRow(cells: r.map((c) => DataCell(Text(c))).toList())).toList(),
    );
  }

  Widget _buildSalesTable(ThemeData theme, List<Map<String, dynamic>> items, double subtotal, double discount, double total) {
    final colorScheme = theme.colorScheme;

    return DataTable(
      headingRowColor: MaterialStateProperty.all(colorScheme.surfaceVariant),
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
          color: MaterialStateProperty.all(colorScheme.surface),
          cells: [
            DataCell(Text('TOTAL', style: const TextStyle(fontWeight: FontWeight.bold))),
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

  /// Builds a summary row widget for the Sales Summary section.
  Widget _summaryRow(String label, String value, {bool bold = false, bool highlight = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: highlight ? colorScheme.surfaceVariant : null,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null)),
          Text(value, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }

  /// Generates the PDF document using the same grouping and filtering logic.
  Future<Uint8List> _generatePdf(
      InventoryReport report,
      SalesSummary summary, {
        required Set<String> includedCategories,
      }) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('yyyy-MM-dd hh:mm a');

    // Filter sales items based on included categories.
    final filteredSalesItems = summary.items.where((item) {
      final prod = widget.productMap[item.productId];
      return prod != null && includedCategories.contains(prod.category);
    }).toList();

    // Group filtered items by (name + price).
    final groupedItems = <String, Map<String, dynamic>>{};
    for (final item in filteredSalesItems) {
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

    // Recalculate totals from filtered grouped items.
    final totalSubtotal = groupedItems.values.fold<double>(0, (sum, item) => sum + item['subtotal']);
    final totalDiscount = groupedItems.values.fold<double>(0, (sum, item) => sum + item['discount']);
    final totalFinal = totalSubtotal - totalDiscount;

    // Also recalc overall sales summary (filtered) if needed.
    final filteredTotalItemsSold = filteredSalesItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final filteredGrossSales = filteredSalesItems.fold<double>(0, (sum, item) => sum + item.subtotal);
    final filteredTotalDiscountAgg = filteredSalesItems.fold<double>(0, (sum, item) => sum + item.discount);
    final filteredNetSales = filteredGrossSales - filteredTotalDiscountAgg;

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
            data: report.startInventory.keys.where((productId) {
              final prod = widget.productMap[productId];
              return prod != null && includedCategories.contains(prod.category);
            }).map((productId) {
              final name = widget.productMap[productId]?.name ?? 'Unknown';
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
              _tableSummaryRow('Items Sold:', '${filteredTotalItemsSold} pcs'),
              _tableSummaryRow('Gross Sales:', 'P${filteredGrossSales.toStringAsFixed(2)}'),
              _tableSummaryRow('Total Discount:', 'P${filteredTotalDiscountAgg.toStringAsFixed(2)}'),
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
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'P${filteredNetSales.toStringAsFixed(2)}',
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

  /// Helper function to build summary rows in the PDF.
  pw.TableRow _tableSummaryRow(String label, String value, {bool bold = false, bool highlight = false}) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    final containerStyle = highlight ? pw.BoxDecoration(color: PdfColors.grey300) : null;
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
}

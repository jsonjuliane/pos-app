import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/features/dashboard/products/data/models/product.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../../data/model/sales_summary.dart';
import '../../data/providers/report_repo_providers.dart';

class SalesSummaryPage extends ConsumerStatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String branchId;
  final Map<String, Product> productMap;

  const SalesSummaryPage({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.branchId,
    required this.productMap,
  });

  @override
  ConsumerState<SalesSummaryPage> createState() => _SalesSummaryPageState();
}

class _SalesSummaryPageState extends ConsumerState<SalesSummaryPage> {
  late Set<String> _includedCategories;

  @override
  void initState() {
    super.initState();
    _includedCategories = {}; // Default all categories later
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Summary'),
      ),
      body: FutureBuilder<List<SalesSummary>>(
        future: ref.read(reportRepoProvider).getSalesSummaries(
          branchId: widget.branchId,
          startDate: widget.startDate,
          endDate: widget.endDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorMessageWidget(
              message: mapFirestoreError(snapshot.error),
              onRetry: () => ref.refresh(reportRepoProvider),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final summaries = snapshot.data!;

          if (summaries.isEmpty) {
            return const Center(child: Text('No sales found in selected range.'));
          }

          // Collect all available categories from productMap
          final allCategories = <String>{};
          for (final summary in summaries) {
            for (final item in summary.items) {
              final product = widget.productMap[item.productId];
              if (product != null) {
                allCategories.add(product.category);
              }
            }
          }

          // Initialize included categories if first build
          if (_includedCategories.isEmpty) {
            _includedCategories = Set<String>.from(allCategories);
          }

          // Filter sales items based on selected categories
          final filteredSummaries = summaries.map((summary) {
            final filteredItems = summary.items.where((item) {
              final product = widget.productMap[item.productId];
              if (product == null) return false;
              return _includedCategories.contains(product.category);
            }).toList();
            return summary.copyWith(items: filteredItems);
          }).toList();

          // Compute totals
          double totalGrossSales = 0;
          double totalDiscount = 0;
          double totalNetSales = 0;
          double totalPaymentCollected = 0;
          double totalItemsSold = 0;

          for (final summary in filteredSummaries) {
            for (final item in summary.items) {
              totalGrossSales += item.subtotal;
              totalDiscount += item.discount;
              totalNetSales += (item.subtotal - item.discount);
              totalItemsSold += item.quantity;
            }
            totalPaymentCollected += summary.paymentCollected;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              Text(
                'Sales Summary (${DateFormat('yMMMd').format(widget.startDate)} - ${DateFormat('yMMMd').format(widget.endDate)})',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Included Categories
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
                          // Prevent unchecking the last selected category
                          if (_includedCategories.length > 1) {
                            _includedCategories.remove(category);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Sales Table
              _buildSalesTable(context, filteredSummaries),

              const SizedBox(height: 24),

              // Totals Section
              Text('Overall Totals', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildTotalRow('Gross Sales', totalGrossSales),
              _buildTotalRow('Total Discount', totalDiscount),
              _buildTotalRow('Net Sales', totalNetSales, bold: true, highlight: true),
              _buildTotalRow('Payment Collected', totalPaymentCollected),
              _buildTotalRow('Items Sold', totalItemsSold.toDouble(), isItems: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSalesTable(BuildContext context, List<SalesSummary> summaries) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final rows = summaries.map((summary) {
      final netSales = summary.items.fold<double>(0, (sum, item) => sum + (item.subtotal - item.discount));
      final dateLabel = summary.date != null
          ? DateFormat('MMM dd, yyyy').format(summary.date!)
          : 'Unknown';

      return [
        dateLabel,
        '₱${summary.grossSales.toStringAsFixed(2)}',
        '₱${summary.totalDiscount.toStringAsFixed(2)}',
        '₱${netSales.toStringAsFixed(2)}',
        '₱${summary.paymentCollected.toStringAsFixed(2)}',
        '${summary.totalItemsSold} pcs',
      ];
    }).toList();

    return DataTable(
      headingRowColor: MaterialStateProperty.all(colorScheme.surfaceVariant),
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Gross Sales')),
        DataColumn(label: Text('Total Discount')),
        DataColumn(label: Text('Net Sales')),
        DataColumn(label: Text('Payment Collected')),
        DataColumn(label: Text('Items Sold')),
      ],
      rows: rows.map((row) {
        return DataRow(cells: row.map((cell) => DataCell(Text(cell))).toList());
      }).toList(),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool bold = false, bool highlight = false, bool isItems = false}) {
    final textStyle = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: highlight ? colorScheme.surfaceVariant : null,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: textStyle),
          ),
          Text(
            isItems ? '${value.toInt()} pcs' : '₱${value.toStringAsFixed(2)}',
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
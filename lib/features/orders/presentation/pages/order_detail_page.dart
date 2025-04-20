import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/product_order.dart';

class OrderDetailPage extends StatelessWidget {
  final ProductOrder order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate order number using hour and minute (12-hour format)
    final orderNumber = DateFormat('mmss').format(order.createdAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Customer Name: ${order.customerName}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Order #$orderNumber',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Order ID: ${order.id}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _infoRow('Created At:', order.createdAt.toLocal().toString()),
            _infoRow('Paid:', order.paid ? 'Yes' : 'No'),
            _infoRow('Discount Applied:', order.discountApplied ? 'Yes' : 'No'),
            if (order.discountApplied)
              _infoRow('Subtotal Amount:', '₱${order.totalAmount.toStringAsFixed(2)}'),
            if (order.discountApplied)
              _infoRow('Discount Amount:', '-₱${order.discountAmount.toStringAsFixed(2)}', important: true),
            _infoRow('Total Amount:', '₱${(order.totalAmount - order.discountAmount).toStringAsFixed(2)}', important: true),
            _infoRow('Payment Amount:', '₱${order.paymentAmount.toStringAsFixed(2)}'),
            _infoRow('Change:', '₱${(order.paymentAmount - (order.totalAmount - order.discountAmount)).toStringAsFixed(2)}', important: true),
            _infoRow('Completed:', order.completed ? 'Yes' : 'No'),
            const SizedBox(height: 16),

            Text(
              'Items:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...order.items.map((item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(item.name),
                subtitle: Text('Quantity: ${item.quantity}'),
                trailing: Text(
                  '₱${item.subtotal.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool important = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: important ? const TextStyle(fontWeight: FontWeight.w600) : null,
          ),
        ],
      ),
    );
  }
}
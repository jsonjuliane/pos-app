import 'package:flutter/material.dart';

import '../../data/models/order_item.dart';

Future<double?> showMarkAsPaidDialog({
  required BuildContext context,
  required List<OrderItem> items,
  required bool discountApplied,
}) async {
  double paymentAmount = 0;
  bool applyDiscount = discountApplied;
  final controller = TextEditingController();

  double getTotal(List<OrderItem> items) {
    return items.fold(0, (sum, item) => sum + item.price * item.quantity);
  }

  OrderItem? getCheapestItem(List<OrderItem> items) {
    if (items.isEmpty) return null;
    return items.reduce((a, b) => a.price < b.price ? a : b);
  }

  return showDialog<double>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final total = getTotal(items);

          final cheapest = getCheapestItem(items);
          final discountAmount = applyDiscount && cheapest != null
              ? cheapest.price * 0.12
              : 0;

          final finalTotal = total - discountAmount;
          final change = (paymentAmount - finalTotal).clamp(0, double.infinity);

          void setQuickAmount(double value) {
            setState(() {
              paymentAmount = value;
              controller.text = value.toStringAsFixed(0);
            });
          }

          return AlertDialog(
            title: const Text('Mark as Paid'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [30, 50, 70, 100, 200, 500].map((amount) {
                    return ChoiceChip(
                      label: Text('₱$amount'),
                      selected: false,
                      onSelected: (_) => setQuickAmount(amount.toDouble()),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Customer Payment Amount',
                  ),
                  onChanged: (value) {
                    setState(() {
                      paymentAmount = double.tryParse(value) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Total: '),
                      if (applyDiscount && cheapest != null)
                        TextSpan(
                          text: '₱${total.toStringAsFixed(2)} - ₱${discountAmount.toStringAsFixed(2)} = ',
                        ),
                      TextSpan(
                        text: '₱${finalTotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (paymentAmount > 0) ...[
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Change: '),
                        TextSpan(
                          text: '₱${change.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => setState(() => applyDiscount = !applyDiscount),
                child: Text(applyDiscount ? 'Remove Discount' : 'Apply Discount'),
              ),
              ElevatedButton(
                onPressed: paymentAmount >= finalTotal
                    ? () => Navigator.pop(context, paymentAmount)
                    : null,
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}
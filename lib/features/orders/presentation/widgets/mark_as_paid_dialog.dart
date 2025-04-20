import 'package:flutter/material.dart';

Future<double?> showMarkAsPaidDialog({
  required BuildContext context,
  required double total,
  required bool discountApplied,
}) async {
  double paymentAmount = 0;
  bool applyDiscount = discountApplied;
  final controller = TextEditingController();

  return showDialog<double>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final discountAmount = applyDiscount ? total * 0.12 : 0;
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
                  runSpacing: 8, // vertical spacing between rows
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
                      if (applyDiscount)
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
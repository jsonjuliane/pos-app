import 'package:flutter/material.dart';

import '../../../cart/data/models/cart_item.dart';

Future<void> showCheckoutConfirmationDialog({
  required BuildContext context,
  required List<CartItem> cartItems,
  required void Function(double paymentAmount, bool payLater) onPay,
}) async {
  double paymentAmount = 0;
  bool discountApplied = false;

  double calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      final itemPrice = item.product.price;
      total += itemPrice * item.quantity;
    }

    if (discountApplied && cartItems.isNotEmpty) {
      final cheapestItem = cartItems.reduce(
        (a, b) => a.product.price < b.product.price ? a : b,
      );
      total -= cheapestItem.product.price * 0.12; // 12% off
    }

    return total;
  }

  await showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Compute total before discount
          final originalTotal = cartItems.fold<double>(
            0,
            (sum, item) => sum + item.product.price * item.quantity,
          );

          // Compute discount details
          final discountedItem =
              cartItems.isNotEmpty
                  ? cartItems.reduce(
                    (a, b) => a.product.price < b.product.price ? a : b,
                  )
                  : null;

          final discountAmount =
              discountedItem != null && discountApplied
                  ? discountedItem.product.price * 0.12
                  : 0.0;

          final totalAfterDiscount = calculateTotal();

          const defaultAmounts = [30, 50, 70, 100, 200, 500, 1000];

          return AlertDialog(
            title: const Text('Confirm Checkout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      defaultAmounts.map((amount) {
                        return ChoiceChip(
                          label: Text('₱$amount'),
                          selected: false,
                          onSelected: (_) {
                            setState(() {
                              paymentAmount = amount.toDouble();
                            });
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Customer Payment Amount',
                  ),
                  controller: TextEditingController(
                    text:
                        paymentAmount == 0
                            ? ''
                            : paymentAmount.toStringAsFixed(0),
                  ),
                  onChanged: (value) {
                    paymentAmount = double.tryParse(value) ?? 0;
                  },
                ),
                const SizedBox(height: 12),
                if (discountApplied && discountedItem != null) ...[
                  Text(
                    'Discount Applied:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${discountedItem.product.name} '
                    '₱${discountedItem.product.price.toStringAsFixed(2)} '
                    '- ₱${discountAmount.toStringAsFixed(2)} '
                    '= ₱${(discountedItem.product.price - discountAmount).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                discountApplied
                    ? Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Total: ',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          TextSpan(
                            text: '₱${originalTotal.toStringAsFixed(2)} ',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          TextSpan(
                            text: '- ₱${discountAmount.toStringAsFixed(2)} ',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const TextSpan(text: '= '),
                          TextSpan(
                            text: '₱${totalAfterDiscount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                    : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Total: ',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          TextSpan(
                            text: '₱${originalTotal.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    discountApplied = !discountApplied;
                  });
                },
                child: Text(
                  discountApplied ? 'Remove Discount' : 'Apply Discount',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onPay(0, true); // Pay Later
                },
                child: const Text('Pay Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onPay(paymentAmount, false);
                },
                child: const Text('Pay'),
              ),
            ],
          );
        },
      );
    },
  );
}

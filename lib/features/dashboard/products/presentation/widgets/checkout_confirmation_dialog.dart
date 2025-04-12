import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/ui_helpers.dart';
import '../../../cart/data/models/cart_item.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../providers/selected_branch_provider.dart';

Future<void> showCheckoutConfirmationDialog({
  required BuildContext context,
  required WidgetRef ref,
  required List<CartItem> cartItems,
  required void Function(double paymentAmount, bool payLater) onPay,
}) async {
  double paymentAmount = 0;
  bool discountApplied = false;

  double calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      total += item.product.price * item.quantity;
    }

    if (discountApplied && cartItems.isNotEmpty) {
      final cheapestItem = cartItems.reduce((a, b) =>
      a.product.price < b.product.price ? a : b);
      total -= cheapestItem.product.price * 0.12; // 12% off
    }

    return total;
  }

  final controller = TextEditingController(
    text: paymentAmount == 0 ? '' : paymentAmount.toStringAsFixed(0),
  );

  await showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          void setPayment(double value) {
            setState(() {
              paymentAmount = value;
              controller.text = paymentAmount == 0 ? '' : paymentAmount.toStringAsFixed(0);
            });
          }

          final originalTotal = cartItems.fold<double>(
            0,
                (sum, item) => sum + item.product.price * item.quantity,
          );

          final discountedItem = cartItems.isNotEmpty
              ? cartItems.reduce((a, b) =>
          a.product.price < b.product.price ? a : b)
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
                // Optional: Customer payment quick chips here
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: defaultAmounts.map((amount) {
                    return ChoiceChip(
                      label: Text('₱$amount'),
                      selected: false,
                      onSelected: (_) {
                        setPayment(amount.toDouble());
                      },
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
                  maxLength: 4,
                ),
                const SizedBox(height: 12),
                if (discountApplied && discountedItem != null) ...[
                  Text(
                    'Discount Applied:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
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
                      const TextSpan(text: 'Total: '),
                      TextSpan(text: '₱${originalTotal.toStringAsFixed(2)} '),
                      TextSpan(text: '- ₱${discountAmount.toStringAsFixed(2)} '),
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
                      const TextSpan(text: 'Total: '),
                      TextSpan(
                        text: '₱${originalTotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (paymentAmount > 0) ...[
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Change: '),
                        TextSpan(
                          text: '₱${(paymentAmount - totalAfterDiscount).clamp(0, double.infinity).toStringAsFixed(2)}',
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    discountApplied = !discountApplied;
                  });
                },
                child: Text(discountApplied ? 'Remove Discount' : 'Apply Discount'),
              ),
              TextButton(
                onPressed: () async {
                  await _handleCheckout(
                    context: context,
                    ref: ref,
                    cartItems: cartItems,
                  );

                  Navigator.of(context).pop();
                  onPay(0, true); // Pay Later
                },
                child: const Text('Pay Later'),
              ),
              ElevatedButton(
                onPressed: paymentAmount >= totalAfterDiscount
                    ? () async {
                  await _handleCheckout(
                    context: context,
                    ref: ref,
                    cartItems: cartItems,
                  );

                  Navigator.of(context).pop();
                  onPay(paymentAmount, false);
                }
                    : null, // disables the button
                child: const Text('Pay'),
              ),

            ],
          );
        },
      );
    },
  );
}

Future<void> _handleCheckout({
  required BuildContext context,
  required WidgetRef ref,
  required List<CartItem> cartItems,
}) async {
  final branchId = ref.read(selectedBranchIdProvider);
  if (branchId == null) {
    showErrorSnackBar(context, 'Branch not selected');
    return;
  }

  try {
    final batch = FirebaseFirestore.instance.batch();

    for (final item in cartItems) {
      final productRef = FirebaseFirestore.instance
          .collection('branches')
          .doc(branchId)
          .collection('products')
          .doc(item.product.id);

      batch.update(productRef, {
        'stockCount': item.product.stockCount - item.quantity,
      });
    }

    await batch.commit();

    ref.read(cartProvider.notifier).clear();
    showSuccessSnackBar(context, 'Checkout successful!');
  } catch (e) {
    showErrorSnackBar(context, 'Checkout failed. Please try again.');
  }
}

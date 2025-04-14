import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/ui_helpers.dart';
import '../../../products/presentation/widgets/checkout_confirmation_dialog.dart';
import '../../data/models/cart_item.dart';
import '../providers/cart_providers.dart';

/// Refined order summary panel for desktop/tablet POS.
/// Shows items with clean layout and a fixed footer.
class OrderSummaryPanel extends ConsumerWidget {
  final List<CartItem> selectedItems;

  const OrderSummaryPanel({super.key, required this.selectedItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = selectedItems.fold<double>(
      0,
          (sum, item) => sum + item.totalPrice,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '🧾 Order Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (selectedItems.isEmpty)
              const Expanded(child: Center(child: Text('Cart is empty')))
            else
              Flexible(
                child: ListView.separated(
                  itemCount: selectedItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final item = selectedItems[index];
                    final product = item.product;
                    final unitPrice = product.price;
                    final subtotal = item.totalPrice;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Product info and price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name + Subtotal
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      product.name +
                                          (product.hasPriceVariants
                                              ? ' (${product.prices.first.name})'
                                              : ''),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '₱${subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'x${item.quantity} • ₱${unitPrice.toStringAsFixed(2)} each',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // + / - Buttons
                          Column(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    ref.read(cartProvider.notifier).remove(product),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              IconButton(
                                onPressed: () =>
                                    ref.read(cartProvider.notifier).add(product, onError: (msg) {
                                      //TODO: Do something if needed
                                    },),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Footer with total and checkout
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(cartProvider.notifier).clear();
                          },
                          child: const Text('Clear Cart'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedItems.isEmpty) {
                              showErrorSnackBar(
                                context,
                                'Cart is empty. Please add items first.',
                              );
                              return;
                            }

                            showCheckoutConfirmationDialog(
                              context: context,
                              ref: ref,
                              cartItems: selectedItems,
                              onPay: (paymentAmount, payLater) {
                                // Payment callback logic
                                print('Paid: ₱$paymentAmount • Pay Later: $payLater');
                              },
                            );
                          },
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

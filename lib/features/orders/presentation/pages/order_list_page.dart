import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/utils/device_helper.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../../../../shared/widgets/select_branch_dialog.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';
import '../../../dashboard/products/presentation/providers/selected_branch_provider.dart';
import '../../../user_management/data/providers/branch_provider.dart';
import '../../data/models/product_order.dart';
import '../../data/providers/order_repo_providers.dart';
import '../provider/complete_date_provider.dart';
import '../widgets/mark_as_paid_dialog.dart';
import 'order_detail_page.dart';

/// A provider to hold the current order search query.
final orderSearchProvider = StateProvider<String>((ref) => '');

class OrderListPage extends ConsumerWidget {
  const OrderListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(selectedBranchIdProvider);
    final authUserAsync = ref.watch(authUserProvider);
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    if (authUserAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (authUserAsync.hasError) {
      return ErrorMessageWidget(
        message: mapFirestoreError(authUserAsync.error),
        onRetry: () => ref.refresh(authUserProvider),
      );
    }

    final user = authUserAsync.value!;
    // Auto-assign branch for non-owner users if not selected.
    if (user.role != 'owner' &&
        user.branchId != null &&
        selectedBranchId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedBranchIdProvider.notifier).set(user.branchId!);
      });
    }

    // Owner with no selected branch: show branch selector.
    if (user.role == 'owner' && selectedBranchId == null) {
      final branchesAsync = ref.watch(allBranchesProvider);
      return Center(
        child: ElevatedButton(
          onPressed:
          branchesAsync.isLoading
              ? null
              : () {
            showDialog(
              context: context,
              builder: (_) => const SelectBranchDialog(),
            );
          },
          child:
          branchesAsync.isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Select Branch'),
        ),
      );
    }

    if (branchId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Listen for orders stream.
    final ordersStream =
    FirebaseFirestore.instance
        .collection('branches')
        .doc(branchId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          actions: [
            if (user.role == 'owner')
              IconButton(
                tooltip: 'Change Branch',
                icon: const Icon(Icons.swap_horiz),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const SelectBranchDialog(),
                  );
                },
              ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Ongoing'), Tab(text: 'Completed')],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: ordersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading orders.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Convert Firestore docs to ProductOrder list.
            final orders =
            snapshot.data!.docs
                .map((doc) => ProductOrder.fromDoc(doc))
                .toList();

            final ordersByOldest = [...orders]
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

            // Retrieve current search query.
            final searchQuery =
            ref.watch(orderSearchProvider).trim().toLowerCase();

            // Filter orders by customer name or order number (derived from creation time).
            final filteredOrders =
            orders.where((order) {
              final customerName = order.customerName.toLowerCase();

              final orderIndex = ordersByOldest.indexWhere((o) => o.id == order.id);
              final dynamicOrderNumber = (orderIndex + 1).toString().padLeft(3, '0');

              return customerName.contains(searchQuery) ||
                  dynamicOrderNumber.contains(searchQuery);

            }).toList();

            // Split into ongoing and completed orders.
            final ongoingOrders =
            filteredOrders.where((o) => !o.completed).toList()
              ..sort(
                    (a, b) => a.createdAt.compareTo(b.createdAt),
              ); // oldest first

            final completedOrders =
            filteredOrders.where((o) => o.completed).toList()
              ..sort(
                    (a, b) => b.updatedAt.compareTo(a.updatedAt),
              ); // newest first
            // already sorted by descending via Firestore

            // Build the search field and TabBarView inside a Column.
            return Column(
              children: [
                // Search Field
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: TextField(
                //     decoration: const InputDecoration(
                //       labelText: 'Search by Customer Name or Order Number',
                //       prefixIcon: Icon(Icons.search),
                //       border: OutlineInputBorder(),
                //     ),
                //     onChanged: (value) {
                //       ref.read(orderSearchProvider.notifier).state = value;
                //     },
                //   ),
                // ),
                // Expanded TabBarView for orders.
                Expanded(
                  child: TabBarView(
                    children: [
                      _OrderGrid(orders: ongoingOrders,
                          branchId: branchId,
                          ordersByOldest: ordersByOldest),
                      _CompletedOrderWithDateFilter(orders: completedOrders,
                          branchId: branchId,
                          ordersByOldest: ordersByOldest),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Grid view for displaying a list of orders.
class _OrderGrid extends StatelessWidget {
  final List<ProductOrder> orders;
  final String branchId;
  final List<ProductOrder> ordersByOldest;

  const _OrderGrid(
      {required this.orders, required this.branchId, required this.ordersByOldest});

  @override
  Widget build(BuildContext context) {
    final deviceType = DeviceHelper.getDeviceType(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child:
      orders.isEmpty
          ? const Center(child: Text('No orders'))
          : GridView.builder(
        itemCount: orders.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: DeviceHelper.getCrossAxisCount(
            deviceType,
            true,
          ),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: DeviceHelper.getChildAspectRatio(
            deviceType,
            "ord",
          ),
        ),
        itemBuilder: (context, index) {
          final order = orders[index];
          final orderIndex = ordersByOldest.indexWhere((o) => o.id == order.id);
          final orderNumber = (orderIndex + 1).toString().padLeft(3, '0');

          return OrderCard(
            order: order,
            branchId: branchId,
            orderNumber: orderNumber,
          );
        },
      ),
    );
  }
}

class _CompletedOrderWithDateFilter extends ConsumerWidget {
  final List<ProductOrder> orders;
  final String branchId;
  final List<ProductOrder> ordersByOldest;

  const _CompletedOrderWithDateFilter({
    required this.orders,
    required this.branchId,
    required this.ordersByOldest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedCompletedDateProvider);
    final deviceType = DeviceHelper.getDeviceType(context);

    // Filter completed orders by selected date (only same day)
    final filteredOrders = selectedDate == null
        ? orders
        : orders.where((order) {
      final date = order.updatedAt;
      return date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                selectedDate == null
                    ? 'Filter by Date'
                    : DateFormat('yMMMd').format(selectedDate),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  ref
                      .read(selectedCompletedDateProvider.notifier)
                      .state = picked;
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(child: Text('No orders for selected date.'))
                : GridView.builder(
              itemCount: filteredOrders.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: DeviceHelper.getCrossAxisCount(
                    deviceType, true),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: DeviceHelper.getChildAspectRatio(
                    deviceType, "ord"),
              ),
              itemBuilder: (context, index) {
                final order = filteredOrders[index];

                // 📦 Get dynamic order number from ordersByOldest
                final orderIndex = ordersByOldest
                    .indexWhere((o) => o.id == order.id);
                final orderNumber =
                (orderIndex + 1).toString().padLeft(3, '0');

                return OrderCard(
                  order: order,
                  branchId: branchId,
                  orderNumber: orderNumber,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A card widget that displays order information.
class OrderCard extends ConsumerStatefulWidget {
  final ProductOrder order;
  final String branchId;
  final String orderNumber;

  const OrderCard(
      {super.key, required this.order, required this.branchId, required this.orderNumber});

  @override
  ConsumerState<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<OrderCard> {
  bool _isLoadingPaid = false;
  bool _isLoadingCompleted = false;

  @override
  Widget build(BuildContext context) {
    final orderRepo = ref.read(orderRepoProvider);
    final order = widget.order;
    final branchId = widget.branchId;
    final orderNumber = widget.orderNumber;

    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailPage(order: order, orderNumber: orderNumber)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${order.customerName}',
                style: Theme
                    .of(
                  context,
                )
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // Order Number (derived from creation time)
              Text(
                'Order #${widget.orderNumber}',
                style: Theme
                    .of(
                  context,
                )
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Items: ${order.items.length}'),
              Text('Paid: ${order.paid ? 'Yes' : 'Pay Later'}'),
              Text('Subtotal: ₱${order.totalAmount.toStringAsFixed(2)}'),
              order.discountApplied
                  ? Text(
                'Discount: -₱${order.discountAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
                  : const Text('Discount: No'),
              Text(
                'Total: ₱${(order.totalAmount - order.discountAmount)
                    .toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Payment Amount: ₱${order.paymentAmount.toStringAsFixed(2)}',
              ),
              Text(
                'Change: ₱${(order.paymentAmount -
                    (order.totalAmount - order.discountAmount)).toStringAsFixed(
                    2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed:
                order.paid || _isLoadingPaid
                    ? null
                    : () async {
                  final payment = await showMarkAsPaidDialog(
                    context: context,
                    items: order.items,
                    discountApplied: order.discountApplied,
                  );

                  if (payment != null) {
                    setState(() => _isLoadingPaid = true);
                    try {
                      await orderRepo.markAsPaid(
                        branchId: branchId,
                        orderId: order.id,
                      );
                    } catch (e) {
                      showErrorSnackBar(
                        context,
                        'Failed to mark as paid',
                      );
                    } finally {
                      setState(() => _isLoadingPaid = false);
                    }
                  }
                },
                child:
                _isLoadingPaid
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : order.paid
                    ? const Text('Paid')
                    : const Text('Mark as Paid'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed:
                order.completed || !order.paid || _isLoadingCompleted
                    ? null
                    : () async {
                  setState(() => _isLoadingCompleted = true);
                  try {
                    await orderRepo.markAsCompleted(
                      branchId: branchId,
                      orderId: order.id,
                    );
                  } catch (e) {
                    showErrorSnackBar(
                      context,
                      'Failed to mark as completed',
                    );
                  } finally {
                    setState(() => _isLoadingCompleted = false);
                  }
                },
                child:
                _isLoadingCompleted
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : order.completed
                    ? const Text('Completed')
                    : const Text('Complete'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

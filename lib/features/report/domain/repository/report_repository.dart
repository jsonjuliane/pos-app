import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../dashboard/cart/data/models/cart_item.dart';
import '../../../dashboard/products/data/models/product.dart';
import '../../../orders/data/models/product_order.dart';
import '../../data/model/inventory_report.dart';
import '../../data/model/sales_summary.dart';

class ReportRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<InventoryReport> _reportCollection(String branchId) {
    return _firestore
        .collection('branches')
        .doc(branchId)
        .collection('inventory_reports')
        .withConverter<InventoryReport>(
          fromFirestore: (doc, _) => InventoryReport.fromDoc(doc),
          toFirestore: (report, _) => report.toMap(),
        );
  }

  Future<void> createReport({
    required String branchId,
    required InventoryReport report,
  }) async {
    final reportRef = _reportCollection(branchId).doc();
    await reportRef.set(report);
  }

  Future<void> updateReport({
    required String branchId,
    required String reportId,
    required Map<String, dynamic> data,
  }) async {
    final reportRef = _reportCollection(branchId).doc(reportId);
    await reportRef.update(data);
  }

  Stream<List<InventoryReport>> getReports(String branchId) {
    return _reportCollection(branchId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<InventoryReport?> getReportByDate({
    required String branchId,
    required DateTime date,
  }) async {
    final query =
        await _reportCollection(branchId)
            .where(
              'date',
              isEqualTo: Timestamp.fromDate(
                DateTime(date.year, date.month, date.day),
              ),
            )
            .limit(1)
            .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first.data();
  }

  Future<List<Product>> getProductsOnce({required String branchId}) async {
    final snapshot =
        await _firestore
            .collection('branches')
            .doc(branchId)
            .collection('products')
            .get();

    return snapshot.docs.map((doc) => Product.fromDoc(doc)).toList();
  }

  Future<SalesSummary> getSalesSummary({
    required String branchId,
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final query =
        await _firestore
            .collection('branches')
            .doc(branchId)
            .collection('orders')
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateOnly),
            )
            .where(
              'createdAt',
              isLessThan: Timestamp.fromDate(
                dateOnly.add(const Duration(days: 1)),
              ),
            )
            .get();

    double grossSales = 0;
    double totalDiscount = 0;
    double paymentCollected = 0;
    int totalItemsSold = 0;
    final itemMap = <String, SalesSummaryItem>{};

    for (final doc in query.docs) {
      final order = ProductOrder.fromDoc(doc);

      grossSales += order.totalAmount;
      totalDiscount += order.discountAmount;
      paymentCollected += order.paymentAmount;

      for (final item in order.items) {
        totalItemsSold += item.quantity;
        final key = '${item.name}-${item.price}-${order.discountApplied}';

        if (itemMap.containsKey(key)) {
          final existing = itemMap[key]!;
          itemMap[key] = SalesSummaryItem(
            name: existing.name,
            price: existing.price,
            discounted: existing.discounted,
            quantity: existing.quantity + item.quantity,
            subtotal: existing.subtotal + item.subtotal,
            discount: existing.discount,
          );
        } else {
          itemMap[key] = SalesSummaryItem(
            name: item.name,
            price: item.price,
            discounted: order.discountApplied,
            quantity: item.quantity,
            subtotal: item.subtotal,
            discount: item.discount,
          );
        }
      }
    }

    return SalesSummary(
      grossSales: grossSales,
      totalDiscount: totalDiscount,
      netSales: grossSales - totalDiscount,
      paymentCollected: paymentCollected,
      totalItemsSold: totalItemsSold,
      items: itemMap.values.toList(),
    );
  }

  Future<void> updateStartAndEndInventoryOnOrder({
    required String branchId,
    required List<CartItem> cartItems,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final reportRef = _reportCollection(branchId).doc(today.toIso8601String());

    final doc = await reportRef.get();
    final report = doc.data(); // InventoryReport from .withConverter

    final startInventory = <String, int>{};
    final endInventory = <String, int>{};

    for (final item in cartItems) {
      final productId = item.product.id;

      endInventory[productId] = item.product.stockCount - item.quantity;

      // If report doesn't exist yet, startInventory is stockCount now
      if (report == null) {
        startInventory[productId] = item.product.stockCount;
      }
    }

    if (report == null) {
      await reportRef.set(
        InventoryReport(
          id: '',
          branchId: branchId,
          date: today,
          startInventory: startInventory,
          addedInventory: {},
          soldInventory: {
            // NEW
            for (final item in cartItems) item.product.id: item.quantity,
          },
          endInventory: endInventory,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return;
    }

    final batch = _firestore.batch();

    final dataToUpdate = <String, dynamic>{'updatedAt': now};

    // Only save startInventory if not existing
    for (final item in cartItems) {
      final productId = item.product.id;

      if (!report.startInventory.containsKey(productId)) {
        dataToUpdate['startInventory.$productId'] = item.product.stockCount;
      }
    }

    // Always increment soldInventory
    for (final item in cartItems) {
      final productId = item.product.id;
      final soldQty = item.quantity;

      dataToUpdate['soldInventory.$productId'] = FieldValue.increment(soldQty);
    }

    // Always update endInventory
    endInventory.forEach((productId, stockCount) {
      dataToUpdate['endInventory.$productId'] = stockCount;
    });

    batch.update(reportRef, dataToUpdate);
    await batch.commit();
  }
}

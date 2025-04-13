import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/model/inventory_report.dart';

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
    final query = await _reportCollection(branchId)
        .where('date', isEqualTo: Timestamp.fromDate(
      DateTime(date.year, date.month, date.day),
    ))
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first.data();
  }

  Future<void> generateReport({
    required String branchId,
  }) async {
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);

    // Fetch existing report
    final existingReport = await getReportByDate(
      branchId: branchId,
      date: todayDateOnly,
    );

    // Fetch products
    final productSnapshot = await _firestore
        .collection('branches')
        .doc(branchId)
        .collection('products')
        .get();

    final startInventory = <String, int>{};
    final endInventory = <String, int>{};

    for (final doc in productSnapshot.docs) {
      final data = doc.data();
      startInventory[doc.id] = data['stockCount'] ?? 0;
      endInventory[doc.id] = data['stockCount'] ?? 0;
    }

    final report = InventoryReport(
      id: existingReport?.id ?? '',
      branchId: branchId,
      date: todayDateOnly,
      startInventory: startInventory,
      addedInventory: existingReport?.addedInventory ?? {},
      endInventory: endInventory,
      createdAt: existingReport?.createdAt ?? now,
      updatedAt: now,
    );

    if (existingReport == null) {
      await createReport(branchId: branchId, report: report);
    } else {
      await updateReport(
        branchId: branchId,
        reportId: existingReport.id,
        data: report.toMap(),
      );
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryReport {
  final String id;
  final String branchId;
  final DateTime date; // YYYY-MM-DD
  final Map<String, int> startInventory;  // productId -> stock count
  final Map<String, int> addedInventory;  // productId -> stock added during the day
  final Map<String, int> soldInventory;
  final Map<String, int> endInventory;    // productId -> stock left at end of day
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryReport({
    required this.id,
    required this.branchId,
    required this.date,
    required this.startInventory,
    required this.addedInventory,
    required this.soldInventory,
    required this.endInventory,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'date': Timestamp.fromDate(date),
      'startInventory': startInventory,
      'addedInventory': addedInventory,
      'soldInventory': soldInventory,
      'endInventory': endInventory,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory InventoryReport.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryReport(
      id: doc.id,
      branchId: data['branchId'],
      date: (data['date'] as Timestamp).toDate(),
      startInventory: Map<String, int>.from(data['startInventory'] ?? {}),
      addedInventory: Map<String, int>.from(data['addedInventory'] ?? {}),
      soldInventory: Map<String, int>.from(data['soldInventory'] ?? {}),
      endInventory: Map<String, int>.from(data['endInventory'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/branch.dart';

class BranchRepository {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Use snapshots() for real-time updates
  Stream<List<Branch>> getAllBranches() {
    final branchRef = _firebaseFirestore.collection('branches');

    return branchRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Branch.fromDoc(doc);
      }).toList();
    });
  }

  // Fetch branch names in real-time using snapshots
  Stream<Map<String, String>> getBranchNames() {
    final branchRef = _firebaseFirestore.collection('branches');

    return branchRef.snapshots().map((snapshot) {
      return {
        for (var doc in snapshot.docs) doc.id: doc['name'] as String,
      };
    });
  }
}
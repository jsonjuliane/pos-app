import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model.dart';

final allBranchesProvider = StreamProvider.autoDispose<List<Branch>>((ref) {
  final branchRef = FirebaseFirestore.instance.collection('branches');

  return branchRef.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return Branch.fromDoc(doc);
    }).toList();
  });
});

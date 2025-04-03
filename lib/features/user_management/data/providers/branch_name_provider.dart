// data/providers/branch_name_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final branchNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('branches').get();
  return {
    for (var doc in snapshot.docs) doc.id: doc['name'] as String,
  };
});
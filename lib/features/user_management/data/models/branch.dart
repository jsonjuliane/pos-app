import 'package:cloud_firestore/cloud_firestore.dart';

class Branch {
  final String id;
  final String name;

  Branch({required this.id, required this.name});

  factory Branch.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Branch(id: doc.id, name: data['name'] ?? 'Unnamed');
  }
}

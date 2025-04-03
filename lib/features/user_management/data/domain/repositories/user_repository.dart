import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../auth/data/models/app_user.dart';

class UserRepository {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Fetch all users, excluding the current user and applying role-based filtering
  Stream<List<AppUser>> getAllUsers(String currentUserRole) {
    final usersRef = _firebaseFirestore.collection('users');

    // Apply the role-based filter: exclude 'owner'
    Query query = usersRef;

    query = query.where('role', whereIn: ['admin', 'staff']);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>))
          .where((user) => user.uid != FirebaseAuth.instance.currentUser?.uid) // Exclude current user
          .toList();
    });
  }
}
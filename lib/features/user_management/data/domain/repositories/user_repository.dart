import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../auth/data/models/app_user.dart';

class UserRepository {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Use snapshots() for real-time updates
  Stream<List<AppUser>> getAllUsers() {
    final usersRef = _firebaseFirestore.collection('users');

    return usersRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromDoc(doc))
          .where(
            (user) => user.uid != FirebaseAuth.instance.currentUser?.uid,
      ) // Exclude current user
          .toList();
    });
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../auth/data/models/app_user.dart';

class UserRepository {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Fetch all users, excluding the current user and applying role-based filtering
  Stream<List<AppUser>> getAllUsers() {
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

  // Fetch a single user by userId
  Future<AppUser?> getUserById(String userId) async {
    try {
      final docSnapshot = await _firebaseFirestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return AppUser.fromDoc(docSnapshot);
      } else {
        return null; // Return null if user doesn't exist
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Toggle the user's status (disabled/enabled)
  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      await userDoc.update({'disabled': !currentStatus});
    } catch (e) {
      throw Exception('Failed to toggle user status: $e');
    }
  }

}
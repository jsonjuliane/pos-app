import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/app_user.dart';

/// Handles Firestore operations related to AppUser.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches the user document by UID from Firestore.
  ///
  /// Returns [AppUser] if the document exists, otherwise `null`.
  Future<AppUser?> getUserByUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists && doc.data() != null) {
      return AppUser.fromDoc(doc);
    }

    return null;
  }
}
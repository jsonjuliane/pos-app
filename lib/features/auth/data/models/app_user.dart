import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an authenticated user of the POS system,
/// stored in Firestore under `/users/{uid}` where `uid` matches Firebase Auth.
///
/// This model supports role-based access and branch-level association.
@immutable
class AppUser {
  /// Firebase Auth UID (also the Firestore document ID)
  final String uid;

  /// Full name of the user (e.g., for display in UI)
  final String name;

  /// Email address of the user (used for login)
  final String email;

  /// Role of the user: can be 'owner', 'admin', or 'staff'
  final String role;

  /// Optional branch ID the user belongs to (null for 'owner' role)
  final String? branchId;

  /// Timestamp when this user was created (nullable)
  final DateTime? createdAt;

  /// Timestamp of last update to user record (nullable)
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.branchId,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates an [AppUser] instance from a Firestore document snapshot.
  ///
  /// This assumes:
  /// - The `uid` is stored as the document ID.
  /// - Required fields are `name`, `email`, and `role`.
  ///
  /// Throws [FormatException] if the document is missing required fields.
  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (data == null) {
      throw const FormatException('User document data is null');
    }

    final name = data['name'];
    final email = data['email'];
    final role = data['role'];

    if (name == null || email == null || role == null) {
      throw const FormatException('Missing required user fields (name, email, role)');
    }

    return AppUser(
      uid: doc.id,
      name: name.toString(),
      email: email.toString(),
      role: role.toString(),
      branchId: data['branchId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts this user into a Firestore-compatible map.
  ///
  /// Used for creating or updating documents in `/users/{uid}`.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (branchId != null) 'branchId': branchId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a POS system user.
@immutable
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? branchId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Whether the account is disabled (e.g., deactivated by owner/admin)
  final bool disabled;

  /// Whether the user must change password on next login
  final bool tempPassword;

  /// Last login timestamp for audit purposes
  final DateTime? lastLogin;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.branchId,
    this.createdAt,
    this.updatedAt,
    this.disabled = false,
    this.tempPassword = false,
    this.lastLogin,
  });

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
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      tempPassword: data['tempPassword'] as bool? ?? false,
      disabled: data['disabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (branchId != null) 'branchId': branchId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'disabled': disabled,
      'tempPassword': tempPassword,
      if (lastLogin != null) 'lastLogin': Timestamp.fromDate(lastLogin!),
    };
  }
}
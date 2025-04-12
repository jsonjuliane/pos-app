// core/utils/error_handler.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String mapFirebaseAuthError(String? codeOrMessage) {
  switch (codeOrMessage) {
    case 'user-not-found':
      return 'No user found with this email.';
    case 'wrong-password':
      return 'Invalid password.';
    case 'invalid-email':
      return 'Email format is incorrect.';
    default:
      return codeOrMessage ?? 'Authentication failed. Please try again.';
  }
}

/// Maps Firestore errors to user-friendly messages.
String mapFirestoreError(Object? error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don’t have permission to do this.';
      case 'not-found':
        return 'Requested data not found.';
      case 'unavailable':
        return 'Service temporarily unavailable.';
      case 'already-exists':
        return 'Item already exists.';
      default:
        return 'Unexpected error. Please try again.';
    }
  }

  // Fallback for non-Firebase errors
  final raw = error.toString();
  if (raw.contains('permission-denied')) return 'You don’t have permission to do this.';
  if (raw.contains('not-found')) return 'Requested data not found.';
  if (raw.contains('unavailable')) return 'Service temporarily unavailable.';

  return 'Unexpected error. Please try again.';
}

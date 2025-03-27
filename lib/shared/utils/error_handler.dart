// core/utils/error_handler.dart

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

  String mapFirestoreError(Object? error) {
  final raw = error.toString();
  if (raw.contains('permission-denied')) return 'You don’t have permission to do this.';
  if (raw.contains('not-found')) return 'Requested data not found.';
  if (raw.contains('unavailable')) return 'Service temporarily unavailable.';
  return 'Unexpected error. Please try again.';
}
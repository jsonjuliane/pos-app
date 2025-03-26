import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';

/// Provides the AuthRepository (for dependency injection).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(); // You can mock this in tests
});
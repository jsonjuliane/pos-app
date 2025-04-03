import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';
import '../domain/repositories/user_repository.dart';

final allUsersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final authUser = ref.watch(authUserProvider).value; // Watch the authUser

  if (authUser == null) return const Stream.empty(); // Ensure we have an authUser

  final userRepository = ref.read(userRepositoryProvider);

  // Fetch users from the repository, applying the filter based on the authUser's role
  return userRepository.getAllUsers(authUser.role);
});

// Using FutureProvider to toggle user status with error handling
final toggleUserStatusProvider = FutureProvider.autoDispose.family<void, String>((ref, userId) async {
  final userRepository = ref.read(userRepositoryProvider);
  try {
    // Get the current user status
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final currentStatus = userDoc.data()?['disabled'] ?? false;

    // Toggle the status in the repository
    await userRepository.toggleUserStatus(userId, currentStatus);
  } catch (e) {
    throw Exception('Failed to toggle user status: $e');
  }
});


final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/app_user.dart';
import '../domain/repositories/user_repository.dart';

// Using StreamProvider to fetch all users in real-time
final allUsersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final userRepository = ref.read(userRepositoryProvider); // Get the user repository instance
  return userRepository.getAllUsers(); // Use the repository to fetch users
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

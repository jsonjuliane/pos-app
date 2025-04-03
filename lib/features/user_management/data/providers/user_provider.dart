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


final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

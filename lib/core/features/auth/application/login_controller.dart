import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/app_user.dart';
import '../data/providers/auth_providers.dart';
import '../data/providers/user_repo_providers.dart';

final loginControllerProvider = StateNotifierProvider<LoginController, AsyncValue<AppUser?>>(
      (ref) => LoginController(ref),
);

class LoginController extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref ref;

  LoginController(this.ref) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signIn(email, password);

      if (user == null) {
        state = const AsyncValue.error('User not found', StackTrace.empty);
        return;
      }

      final userRepo = ref.read(userRepositoryProvider);
      final appUser = await userRepo.getUserByUid(user.uid);

      if (appUser == null) {
        state = const AsyncValue.error('App user record not found', StackTrace.empty);
        return;
      }

      state = AsyncValue.data(appUser);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Authentication error', StackTrace.current);
    } catch (e, st) {
      state = AsyncValue.error('Unexpected error occurred', st);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }
}

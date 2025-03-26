import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../presentation/providers/auth_providers.dart';

/// A StateNotifier that manages login state and loading/error handling.
class LoginController extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;

  LoginController(this.ref) : super(const AsyncValue.data(null));

  /// Attempts to sign in using email and password.
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final user = await ref.read(authRepositoryProvider).signIn(email, password);
      state = AsyncValue.data(user);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Authentication failed', StackTrace.current);
    } catch (e, st) {
      state = AsyncValue.error('Something went wrong', st);
    }
  }

  /// Logs the user out.
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }
}

/// Exposes the LoginController via Riverpod.
final loginControllerProvider =
StateNotifierProvider<LoginController, AsyncValue<User?>>(
      (ref) => LoginController(ref),
);
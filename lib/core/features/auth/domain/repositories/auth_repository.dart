import 'package:firebase_auth/firebase_auth.dart';

/// Repository that handles all Firebase authentication operations.
class AuthRepository {
  final FirebaseAuth _auth;

  /// Create an instance of [AuthRepository] with an optional [FirebaseAuth] (for testing).
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  /// Sign in using email and password.
  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get the currently authenticated user, or null if not signed in.
  User? get currentUser => _auth.currentUser;
}
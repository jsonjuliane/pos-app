import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/app_user.dart';
import '../../data/providers/user_repo_providers.dart';

final authUserProvider = FutureProvider<AppUser?>((ref) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) return null;

  final userRepo = ref.read(userRepositoryProvider);
  return await userRepo.getUserByUid(firebaseUser.uid);
});
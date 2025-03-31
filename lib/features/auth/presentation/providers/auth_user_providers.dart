import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/app_user.dart';
import '../../data/providers/user_repo_providers.dart';

final authUserProvider = StreamProvider<AppUser?>((ref) {
  return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
    if (user == null) return null;

    final userRepo = ref.read(userRepositoryProvider);
    return await userRepo.getUserByUid(user.uid);
  });
});

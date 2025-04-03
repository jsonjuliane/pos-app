import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';

final allUsersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final authUser = ref.watch(authUserProvider).value;

  if (authUser == null) return const Stream.empty();

  final usersRef = FirebaseFirestore.instance.collection('users');

  Query query = usersRef;

  if (authUser.role == 'admin') {
    query = query.where('role', isNotEqualTo: 'owner');
  }

  return query.snapshots().map((snapshot) {
    return snapshot.docs
        .map(
          (doc) => AppUser.fromDoc(
            doc as QueryDocumentSnapshot<Map<String, dynamic>>,
          ),
        )
        .where((user) => user.uid != authUser.uid) // Exclude the current user
        .toList();
  });
});

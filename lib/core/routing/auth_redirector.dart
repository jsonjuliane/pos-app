import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_user_providers.dart';

class AuthRedirector extends ConsumerWidget {
  final Widget child;
  const AuthRedirector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUserAsync = ref.watch(authUserProvider);

    return authUserAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          // GoRouter handles redirection outside of here
          return const SizedBox(); // Prevents flashing
        }
        return child;
      },
    );
  }
}
// lib/core/routing/app_router.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/products/presentation/pages/product_list_page.dart';
import 'go_router_refresh_stream.dart';


class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/login';

      if (firebaseUser == null) {
        return isLoggingIn ? null : '/login';
      } else {
        return isLoggingIn ? '/dashboard' : null;
      }
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const ProductListPage(),
      ),
    ],
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  );
}

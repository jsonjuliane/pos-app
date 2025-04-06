import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/products/presentation/pages/product_list_page.dart';
import '../../features/user_management/presentation/pages/user_management_page.dart';
import '../../shared/widgets/navigation_scaffold.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/login';

      // Redirect root `/` to proper page
      if (state.matchedLocation == '/') {
        return firebaseUser == null ? '/login' : '/dashboard';
      }

      if (firebaseUser == null) {
        return isLoggingIn ? null : '/login';
      } else {
        return isLoggingIn ? '/dashboard' : null; // 👈 redirect authenticated users to home
      }
    },
    routes: [
      // Standalone Login route
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // Shell route for layout-shared pages (dashboard, users, etc)
      ShellRoute(
        builder: (context, state, child) {
          return NavigationScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const ProductListPage(),
          ),
          GoRoute(
            path: '/users',
            name: 'user-management',
            builder: (context, state) => const UserManagementPage(),
          ),
          // Add settings and other routes here
        ],
      ),
    ],
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
  );
}

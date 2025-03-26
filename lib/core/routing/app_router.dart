import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/products/presentation/pages/product_list_page.dart';

/// Application-wide router configuration using go_router.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login', // Temporarily start from login page
    routes: [
      // 🔐 Login Page
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // 🛒 Dashboard (Product List Page)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const ProductListPage(),
      ),
    ],
  );
}

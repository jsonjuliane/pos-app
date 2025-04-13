import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/products/presentation/pages/product_list_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/report/presentation/pages/report_list_page.dart';
import '../../features/orders/presentation/pages/order_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/user_management/presentation/pages/user_management_page.dart';
import '../../shared/widgets/navigation_scaffold.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/login';

      if (user == null && !isLoggingIn) {
        return '/login';
      }

      if (user != null && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
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
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrderListPage(),
          ),
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            builder: (context, state) => const InventoryPage(),
          ),
          GoRoute(
            path: '/reports',
            name: 'inventory-reports',
            builder: (context, state) => const ReportListPage(),
          ),
          GoRoute(
            path: '/users',
            name: 'user-management',
            builder: (context, state) => const UserManagementPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
  );
}

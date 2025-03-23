import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/products/presentation/product_list_page.dart';

/// Application-wide router configuration using go_router.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'products',
        builder: (context, state) => const ProductListPage(),
      ),
    ],
  );
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_user_providers.dart';

class NavigationScaffold extends ConsumerWidget {
  final Widget child;

  const NavigationScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);
    final isWide = MediaQuery.of(context).size.width >= 700;
    final location = GoRouterState.of(context).uri.toString();

    final user = userAsync.asData?.value;
    final isAdminOrOwner = user?.role == 'admin' || user?.role == 'owner';

    // Use a list of map entries to hold label, icon, and route
    final navItems = <Map<String, dynamic>>[
      {
        'label': 'Dashboard',
        'icon': const Icon(Icons.dashboard),
        'route': '/dashboard',
      },
      if (isAdminOrOwner)
        {
          'label': 'Inventory',
          'icon': const Icon(Icons.inventory_2_outlined),
          'route': '/inventory',
        },
      if (isAdminOrOwner)
        {
          'label': 'Users',
          'icon': const Icon(Icons.group),
          'route': '/users',
        },
      {

        'label': 'Settings',
        'icon': const Icon(Icons.settings),
        'route': '/settings',
      },
    ];

    // Determine selected index based on current location
    final selectedIndex = navItems.indexWhere((item) {
      final route = item['route'] as String;
      return location.startsWith(route);
    }).clamp(0, navItems.length - 1);

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                final route = navItems[index]['route'] as String;
                context.go(route);
              },
              labelType: NavigationRailLabelType.all,
              destinations: navItems.map((item) {
                return NavigationRailDestination(
                  icon: item['icon'],
                  label: Text(item['label']),
                );
              }).toList(),
            ),
          Expanded(child: SafeArea(child: child)),
        ],
      ),
      bottomNavigationBar: !isWide
          ? NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final route = navItems[index]['route'] as String;
          context.go(route);
        },
        destinations: navItems.map((item) {
          return NavigationDestination(
            icon: item['icon'],
            label: item['label'],
          );
        }).toList(),
      )
          : null,
    );
  }
}

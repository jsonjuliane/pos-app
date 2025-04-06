import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationScaffold extends StatelessWidget {
  final Widget child;

  const NavigationScaffold({super.key, required this.child});

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.group), label: 'Users'),
    NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isWide = MediaQuery.of(context).size.width >= 700;

    int selectedIndex = () {
      if (location.startsWith('/users')) return 1;
      if (location.startsWith('/settings')) return 2;
      return 0;
    }();

    void onDestinationSelected(int index) {
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/users');
          break;
        case 2:
          context.go('/settings');
          break;
      }
    }

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((e) => NavigationRailDestination(
                icon: e.icon,
                label: Text(e.label),
              ))
                  .toList(),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: !isWide
          ? NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: _destinations,
      )
          : null,
    );
  }
}

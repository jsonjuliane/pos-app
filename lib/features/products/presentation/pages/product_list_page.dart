import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/providers/theme_mode_provider.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/utils/logout_helper.dart';
import '../../../../shared/widgets/error_message_widget.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';
import '../../../cart/data/models/cart_item.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/order_summary_panel.dart';
import '../../data/models/product.dart';
import '../providers/product_providers.dart';
import '../providers/selected_category_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/product_card.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual<String>(selectedCategoryProvider, (_, __) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final authUserAsync = ref.watch(authUserProvider);
    final productListAsync = ref.watch(productListProvider);

    if (authUserAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authUserAsync.hasError) {
      return Scaffold(
        body: ErrorMessageWidget(
          message: mapFirestoreError(authUserAsync.error),
          onRetry: () => ref.refresh(authUserProvider),
        ),
      );
    }

    final user = authUserAsync.value;
    if (user == null) {
      // This can happen during logout or before redirect
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final cartItems = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Products'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeModeProvider);
              final platformBrightness =
                  MediaQuery.of(context).platformBrightness;

              final isDark =
                  themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system &&
                      platformBrightness == Brightness.dark);

              return IconButton(
                tooltip:
                    isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .toggle(platformBrightness);
                },
              );
            },
          ),
        ],
      ),
      drawer: !isWide ? _AppDrawer(user: user, ref: ref) : null,
      body: Row(
        children: [
          if (isWide) _NavigationRail(user: user, ref: ref),
          Expanded(
            child: productListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (err, _) => ErrorMessageWidget(
                    message: mapFirestoreError(err),
                    onRetry: () => ref.refresh(productListProvider),
                  ),
              data:
                  (products) => _MainContent(
                    scrollController: _scrollController,
                    products: products,
                    cartItems: cartItems,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainContent extends ConsumerWidget {
  final ScrollController scrollController;
  final List<Product> products;
  final List<CartItem> cartItems;

  const _MainContent({
    required this.scrollController,
    required this.products,
    required this.cartItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filtered =
        selectedCategory.toLowerCase() == 'all'
            ? products
            : products
                .where(
                  (p) =>
                      p.category.toLowerCase() ==
                      selectedCategory.toLowerCase(),
                )
                .toList();

    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CategorySelector(products: products),
                const SizedBox(height: 12),
                Expanded(
                  child: ProductGrid(
                    products: filtered,
                    controller: scrollController,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(flex: 3, child: OrderSummaryPanel(selectedItems: cartItems)),
      ],
    );
  }
}

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final ScrollController controller;

  const ProductGrid({
    super.key,
    required this.products,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}

class _NavigationRail extends ConsumerWidget {
  final AppUser user;
  final WidgetRef ref;

  const _NavigationRail({required this.user, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // Build list of destinations dynamically
    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.shopping_cart),
        label: Text('Products'),
      ),
      if (user.role == 'owner' || user.role == 'admin')
        const NavigationRailDestination(
          icon: Icon(Icons.supervised_user_circle),
          label: Text('User'),
        ),
      const NavigationRailDestination(
        icon: Icon(Icons.logout),
        label: Text('Logout'),
      ),
    ];

    // Determine selectedIndex based on current route
    int selectedIndex;
    if (currentRoute == '/dashboard') {
      selectedIndex = 0;
    } else if (currentRoute == '/user-management') {
      selectedIndex = 1;
    } else {
      selectedIndex = -1; // Nothing selected
    }

    return NavigationRail(
      selectedIndex: selectedIndex,
      labelType: NavigationRailLabelType.all,
      destinations: destinations,
      onDestinationSelected: (index) async {
        final isAdminOrOwner = user.role == 'owner' || user.role == 'admin';

        // Adjust index based on destination count
        if (index == 0) {
          context.goNamed('dashboard');
        } else if (index == 1 && isAdminOrOwner) {
          context.goNamed('user-management');
        } else if ((index == 1 && !isAdminOrOwner) || index == 2) {
          await showLogoutDialog(context, ref);
        }
      },
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final AppUser user;
  final WidgetRef ref;

  const _AppDrawer({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Text('POS App')),
          // ✅ Add Products nav item (default page)
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Products'),
            selected: GoRouterState.of(context).matchedLocation == '/dashboard',
            onTap: () => context.goNamed('dashboard'),
          ),
          if (user.role == 'owner' || user.role == 'admin')
            ListTile(
              leading: const Icon(Icons.supervised_user_circle),
              title: const Text('User'),
              onTap: () => context.goNamed('user-management'),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }
}

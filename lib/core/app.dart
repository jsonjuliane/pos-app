import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/theme_mode_provider.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget of the POS app.
/// Sets the global theme and attaches the router configuration.
class POSApp extends ConsumerWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      themeModeProvider,
    ); // 👈 Watch the current theme

    return MaterialApp.router(
      title: 'POS App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}

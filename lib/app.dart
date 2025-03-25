import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';


/// Root widget of the POS app.
/// Sets the global theme and attaches the router configuration.
class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'POS App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // Automatically switch based on system setting
      // Connects go_router navigation to the app
      routerConfig: AppRouter.router,
    );
  }
}

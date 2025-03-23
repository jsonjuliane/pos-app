import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';


/// Root widget of the POS app.
/// Sets the global theme and attaches the router configuration.
class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'POS App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Material 3 design system
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,

        // Custom global text theme can be added here later
      ),
      // Connects go_router navigation to the app
      routerConfig: AppRouter.router,
    );
  }
}

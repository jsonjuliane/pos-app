import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Entry point of the POS app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Add Hive initialization here later

  runApp(
    const ProviderScope(
      child: POSApp(),
    ),
  );
}
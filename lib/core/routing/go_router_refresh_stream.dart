import 'dart:async';
import 'package:flutter/foundation.dart';

/// Custom implementation of GoRouterRefreshStream for older go_router versions.
/// Listens to a stream (e.g. FirebaseAuth.authStateChanges) and notifies GoRouter to re-evaluate redirects.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
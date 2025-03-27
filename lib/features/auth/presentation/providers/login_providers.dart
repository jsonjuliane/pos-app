import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/login_controller.dart';

/// Holds form state temporarily
final loginEmailProvider = StateProvider.autoDispose<String>((ref) => '');
final loginPasswordProvider = StateProvider.autoDispose<String>((ref) => '');

/// Connects the controller logic
final loginControllerProvider =
StateNotifierProvider<LoginController, AsyncValue>(
      (ref) => LoginController(ref),
);
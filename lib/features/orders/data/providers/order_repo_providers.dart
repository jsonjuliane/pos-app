import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/order_repository.dart';

final orderRepoProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

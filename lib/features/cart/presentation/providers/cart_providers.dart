import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cart_item.dart';
import '../../application/cart_notifier.dart';

final cartProvider =
StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());
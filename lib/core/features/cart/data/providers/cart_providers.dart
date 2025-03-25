import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/cart_notifier.dart';
import '../models/cart_item.dart';

final cartProvider =
StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());
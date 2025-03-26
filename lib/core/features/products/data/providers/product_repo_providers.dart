import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/product_repository.dart';

/// Provides a singleton instance of ProductRepository for DI.
final productRepoProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product.dart';
import '../../data/providers/product_repo_providers.dart';

/// Provides the live list of products to the UI as a stream.
final productListProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.read(productRepoProvider);
  return repo.getProducts();
});

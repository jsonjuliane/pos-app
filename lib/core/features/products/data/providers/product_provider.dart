import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/product_repository.dart';
import '../models/product.dart';

final productRepoProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productListProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.read(productRepoProvider);
  return repo.getProducts();
});

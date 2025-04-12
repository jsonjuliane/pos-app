import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/inventory_repository.dart';

/// Provides the InventoryRepository instance for DI.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

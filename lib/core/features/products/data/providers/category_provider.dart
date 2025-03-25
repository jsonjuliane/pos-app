import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the currently selected category for filtering products.
/// Defaults to "all" to show everything.
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');
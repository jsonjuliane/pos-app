import 'models/category.dart';

/// List of available product categories for filtering.
/// Add more as your menu grows.
const categories = <Category>[
  Category(id: 'all', label: 'All'),
  Category(id: 'platter', label: 'Platter'),
  Category(id: 'snack', label: 'Snack'),
  Category(id: 'drinks', label: 'Drinks'),
];
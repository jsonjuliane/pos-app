import 'package:flutter/material.dart';

/// Landing screen for the POS app.
/// This will later display a grid or list of products for sale.
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: const Center(
        child: Text(
          'This will be the product list!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../data/models/product.dart';

/// Product card with:
/// - Single tap to add 1
/// - Long press to remove 1
class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _count = 0;

  void _increment() => setState(() => _count++);

  void _decrement() {
    if (_count > 0) setState(() => _count--);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _increment,
      onLongPress: _decrement,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  widget.product.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _count > 0 ? 'In cart: $_count' : 'Tap to add • Long press to remove',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _count > 0 ? Theme.of(context).primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
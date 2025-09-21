import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product p;
  final VoidCallback onAdd;
  final VoidCallback onBuyNow;
  final VoidCallback? onChat;
  const ProductCard({super.key, required this.p, required this.onAdd, required this.onBuyNow, this.onChat});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(p.imageUrl.isNotEmpty ? p.imageUrl : 'https://via.placeholder.com/64',
                  width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${p.company} • ${p.location}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('${p.quantity} • Rs. ${p.price}', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                ElevatedButton(onPressed: onBuyNow, child: const Text('Buy Now')),
                const SizedBox(height: 6),
                OutlinedButton(onPressed: onAdd, child: const Text('Add to Cart')),
                if (onChat != null) TextButton(onPressed: onChat, child: const Text('Chat')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

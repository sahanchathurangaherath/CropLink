import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/local_image_widget.dart';

class ProductCard extends StatelessWidget {
  final Product p;
  final VoidCallback onAdd;
  final VoidCallback onBuyNow;
  final VoidCallback? onChat;
  const ProductCard(
      {super.key,
      required this.p,
      required this.onAdd,
      required this.onBuyNow,
      this.onChat});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            p.localImagePath != null
                ? LocalImageWidget(
                    fileName: p.localImagePath!,
                    height: 200,
                    width: double.infinity,
                  )
                : Image.network(
                    p.imageUrl.isNotEmpty
                        ? p.imageUrl
                        : 'https://via.placeholder.com/64',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('${p.company} • ${p.location}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('${p.quantity} • Rs. ${p.price}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    ElevatedButton(
                        onPressed: onBuyNow, child: const Text('Buy Now')),
                    const SizedBox(height: 6),
                    OutlinedButton(
                        onPressed: onAdd, child: const Text('Add to Cart')),
                    if (onChat != null)
                      TextButton(onPressed: onChat, child: const Text('Chat')),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

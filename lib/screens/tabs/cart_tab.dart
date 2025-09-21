import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: cart.items.length,
              itemBuilder: (_, i) {
                final it = cart.items[i];
                return ListTile(
                  title: Text(it.product.name),
                  subtitle: Text('Qty: ${it.qty} • Rs. ${it.product.price}'),
                  trailing: Text('Rs. ${it.total}'),
                );
              },
              separatorBuilder: (_, __) => const Divider(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Total: Rs. ${cart.grandTotal}', textAlign: TextAlign.end, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton(onPressed: cart.items.isEmpty ? null : () {}, child: const Text('Checkout')),
        ],
      ),
    );
  }
}

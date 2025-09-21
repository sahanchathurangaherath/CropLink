import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/product_card.dart';
import '../post_item.dart';

class CatalogTab extends StatelessWidget {
  const CatalogTab({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CatalogProvider>();
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              SegmentedButton(
                segments: const [
                  ButtonSegment(value: 'buyer', label: Text('Buyer'), icon: Icon(Icons.store)),
                  ButtonSegment(value: 'seller', label: Text('Seller'), icon: Icon(Icons.agriculture)),
                ],
                selected: <String>{auth.role},
                onSelectionChanged: (s) => context.read<AuthProvider>().setRole(s.first),
              ),
              const SizedBox(width: 8),
              if (auth.role == 'seller')
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostItemScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('Post'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const SearchBarWidget(),
          const SizedBox(height: 8),
          const CategoryChips(),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder(
              stream: prov.products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) return const Center(child: Text('No products'));
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final p = list[i];
                    return ProductCard(
                      p: p,
                      onAdd: () => cart.add(p),
                      onBuyNow: () {},
                      onChat: auth.role == 'seller' ? () {} : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

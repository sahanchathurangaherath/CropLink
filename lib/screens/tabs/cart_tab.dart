import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  Future<void> _removeCartItem(
      BuildContext context, String userId, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(docId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from cart')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error removing item: $e')));
      }
    }
  }

  Future<void> _checkout(BuildContext context, String userId,
      List<QueryDocumentSnapshot> docs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Checkout'),
        content: const Text('Proceed to checkout and clear cart?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();
    try {
      for (final d in docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checkout complete. Cart cleared.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text('Please sign in to view your cart',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }

    final cartStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: cartStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        double grandTotal = 0;
        final items = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final price = (data['price'] is num)
              ? (data['price'] as num).toDouble()
              : double.tryParse('${data['price']}') ?? 0.0;
          final qty = (data['quantity'] is int)
              ? data['quantity'] as int
              : (int.tryParse('${data['quantity']}') ?? 0);
          final total = price * qty;
          grandTotal += total;
          return {
            'docId': d.id,
            'name': data['name'] ?? '',
            'price': price,
            'qty': qty,
            'total': total,
            'imageUrl': data['imageUrl'],
          };
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Your cart is empty'))
                    : ListView.separated(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return ListTile(
                            leading: it['imageUrl'] != null
                                ? Image.network(it['imageUrl'],
                                    width: 56, height: 56, fit: BoxFit.cover)
                                : const SizedBox(width: 56, height: 56),
                            title: Text(it['name']),
                            subtitle: Text(
                                'Qty: ${it['qty']} • Rs. ${it['price'].toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Rs. ${it['total'].toStringAsFixed(2)}'),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeCartItem(
                                      context, user.uid, it['docId']),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(),
                      ),
              ),
              const SizedBox(height: 12),
              Text('Total: Rs. ${grandTotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: items.isEmpty
                    ? null
                    : () => _checkout(context, user.uid, snapshot.data!.docs),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17904A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Checkout'),
              ),
            ],
          ),
        );
      },
    );
  }
}

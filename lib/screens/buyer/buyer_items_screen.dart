import 'package:flutter/material.dart';
import '../../models/category_items.dart';

class BuyerItemsScreen extends StatelessWidget {
  final String category;

  const BuyerItemsScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final items = CategoryItems.getItemsForCategory(category);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17904A),
        title: Text(category),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ItemSearchDelegate(items),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _ItemCard(
            name: items[index],
            quantity: '500g',
            priceRange: 'Rs.240-280',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(itemName: items[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String name;
  final String quantity;
  final String priceRange;
  final VoidCallback onTap;

  const _ItemCard({
    required this.name,
    required this.quantity,
    required this.priceRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                quantity,
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                priceRange,
                style: const TextStyle(
                  color: Color(0xFF17904A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name added to cart!')),
                  );
                  // Add actual cart logic here if you have a provider
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17904A),
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: const Text(
                  'ADD',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Search Delegate ---
class ItemSearchDelegate extends SearchDelegate<String> {
  final List<String> items;
  ItemSearchDelegate(this.items);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = items
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]),
          onTap: () {
            close(context, results[index]);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(itemName: results[index]),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = items
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}

// --- Item Detail Screen ---
class ItemDetailScreen extends StatelessWidget {
  final String itemName;
  const ItemDetailScreen({super.key, required this.itemName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
        backgroundColor: const Color(0xFF17904A),
      ),
      body: Center(
        child: Text('Details for $itemName'),
      ),
    );
  }
}

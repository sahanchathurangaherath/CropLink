import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import 'tabs/weather_tab.dart';
import 'tabs/cart_tab.dart';
import 'tabs/account_tab.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(
        onOpenCategory: (cat) {
          final isSeller = context.read<AuthProvider>().role == 'seller';
          Navigator.pushNamed(
            context,
            isSeller
                ? AppRoutes.sellerSubcategories
                : AppRoutes.buyerSubcategories,
            arguments: cat,
          );
        },
      ),
      const WeatherTab(),
      const CartTab(),
      const AccountTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF17904A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, _, __) => const SizedBox(height: 40),
            ),
            const SizedBox(height: 4),
            Text(
              'CROP LINK',
              style: TextStyle(
                color: Colors.yellow[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Consumer<AuthProvider>(
              builder: (context, auth, _) => Text(
                auth.role == 'seller' ? 'Seller Mode' : 'Buyer Mode',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => setState(() => _currentIndex = 4), // Account tab
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onOpenCategory});
  final void Function(String category) onOpenCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search for products',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _CategoryCard(
                  title: 'Vegetables',
                  imagePath: 'assets/images/vegetables.png',
                  onTap: () => onOpenCategory('vegetables'),
                ),
                _CategoryCard(
                  title: 'Fruits',
                  imagePath: 'assets/images/fruits.png',
                  onTap: () => onOpenCategory('fruits'),
                ),
                _CategoryCard(
                  title: 'Grains',
                  imagePath: 'assets/images/grains.png',
                  onTap: () => onOpenCategory('grains'),
                ),
                _CategoryCard(
                  title: 'Leafy Greens',
                  imagePath: 'assets/images/leafy_greens.png',
                  onTap: () => onOpenCategory('leafy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 80, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int qty;
  CartItem(this.product, this.qty);
  int get total => product.price * qty;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList(growable: false);
  int get grandTotal => _items.values.fold(0, (s, it) => s + it.total);

  void add(Product p, {int qty = 1}) {
    final e = _items[p.id];
    if (e != null) {
      e.qty += qty;
    } else {
      _items[p.id] = CartItem(p, qty);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

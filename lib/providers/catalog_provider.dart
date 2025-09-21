import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class CatalogProvider with ChangeNotifier {
  final _svc = ProductService();
  String _query = '';
  String _category = 'all';

  String get query => _query;
  String get category => _category;

  set query(String v) {
    _query = v;
    notifyListeners();
  }
  set category(String v) {
    _category = v;
    notifyListeners();
  }

  Stream<List<Product>> get products => _svc.streamProducts(category: _category, query: _query);
}

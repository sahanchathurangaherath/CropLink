import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final _col = FirebaseFirestore.instance.collection('products').withConverter<Product>(
    fromFirestore: (snap, _) => Product.fromDoc(snap),
    toFirestore: (p, _) => p.toMap(),
  );

  Stream<List<Product>> streamProducts({String? category, String? query}) {
    Query<Product> q = _col.orderBy('createdAt', descending: true);
    if (category != null && category != 'all') {
      q = q.where('category', isEqualTo: category);
    }
    return q.snapshots().map((s) {
      final list = s.docs.map((d) => d.data()).toList(growable: false);
      if (query == null || query.isEmpty) return list;
      final ql = query.toLowerCase();
      return list.where((p) => p.name.toLowerCase().contains(ql)).toList(growable: false);
    });
  }

  Future<void> addProduct(Product p) async {
    await _col.add(p);
  }
}

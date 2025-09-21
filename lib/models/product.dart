import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String company;
  final String quantity;
  final int price;
  final String location;
  final String imageUrl;
  final String sellerUid;
  final double rating;
  final Timestamp createdAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.company,
    required this.quantity,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.sellerUid,
    required this.rating,
    required this.createdAt,
  });

  factory Product.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc) {
    final d = doc.data()!;
    return Product(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      company: d['company'] ?? '',
      quantity: d['quantity'] ?? '',
      price: (d['price'] ?? 0) as int,
      location: d['location'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      sellerUid: d['sellerUid'] ?? '',
      rating: (d['rating'] ?? 0).toDouble(),
      createdAt: (d['createdAt'] ?? Timestamp.now()) as Timestamp,
    );
  }

  Map<String,dynamic> toMap() => {
    'name': name,
    'category': category,
    'company': company,
    'quantity': quantity,
    'price': price,
    'location': location,
    'imageUrl': imageUrl,
    'sellerUid': sellerUid,
    'rating': rating,
    'createdAt': createdAt,
  };
}

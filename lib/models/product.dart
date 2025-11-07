import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final int price;
  final String quantity;
  final String imageUrl;
  String? localImagePath;
  final Timestamp createdAt;
  final String sellerUid;
  final String category;
  final String company;
  final String location;
  final int rating;
  final Map<String, dynamic> details;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.localImagePath,
    required this.createdAt,
    required this.sellerUid,
    required this.category,
    required this.company,
    required this.location,
    required this.rating,
    Map<String, dynamic>? details,
  }) : details = details ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'createdAt': createdAt,
      'sellerUid': sellerUid,
      'category': category,
      'company': company,
      'location': location,
      'rating': rating,
      'details': details,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      quantity: map['quantity'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      localImagePath: map['localImagePath'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      sellerUid: map['sellerUid'] ?? '',
      category: map['category'] ?? '',
      company: map['company'] ?? '',
      location: map['location'] ?? '',
      rating: map['rating'] ?? 0,
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Product(
      id: doc.id,
      name: d['name'] ?? '',
      price: (d['price'] ?? 0) as int,
      quantity: d['quantity'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      localImagePath: d['localImagePath'],
      createdAt: (d['createdAt'] ?? Timestamp.now()) as Timestamp,
      sellerUid: d['sellerUid'] ?? '',
      category: d['category'] ?? '',
      company: d['company'] ?? '',
      location: d['location'] ?? '',
      rating: (d['rating'] ?? 0) as int,
      details: d['details'] ?? {},
    );
  }
}

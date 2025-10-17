import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User Methods
  Future<void> createUser({
    required String uid,
    required String email,
    required String role,
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'role': role,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  // Cart Methods
  Future<void> addToCart({
    required String userId,
    required String itemId,
    required int quantity,
    required double price,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId)
        .set({
      'itemId': itemId,
      'quantity': quantity,
      'price': price,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Category Methods
  Future<void> createCategory({
    required String name,
    String? imageUrl,
  }) async {
    await _db.collection('categories').add({
      'name': name,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Subcategory Methods
  Future<void> createSubcategory({
    required String categoryId,
    required String name,
    String? imageUrl,
  }) async {
    await _db
        .collection('categories')
        .doc(categoryId)
        .collection('subcategories')
        .add({
      'name': name,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Item Methods
  Future<void> createItem({
    required String categoryId,
    required String subcategoryId,
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String unit,
    required String sellerUid,
    String? imageUrl,
  }) async {
    await _db
        .collection('categories')
        .doc(categoryId)
        .collection('subcategories')
        .doc(subcategoryId)
        .collection('items')
        .add({
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'imageUrl': imageUrl,
      'sellerUid': sellerUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Rating Methods
  Future<void> addRating({
    required String categoryId,
    required String subcategoryId,
    required String itemId,
    required String userId,
    required double rating,
    String? review,
  }) async {
    await _db
        .collection('categories')
        .doc(categoryId)
        .collection('subcategories')
        .doc(subcategoryId)
        .collection('items')
        .doc(itemId)
        .collection('ratings')
        .add({
      'userId': userId,
      'rating': rating,
      'review': review,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Order Methods
  Future<String> createOrder({
    required String buyerId,
    required String sellerId,
    required double totalAmount,
    required Map<String, dynamic> shippingAddress,
    required List<Map<String, dynamic>> items,
  }) async {
    final docRef = await _db.collection('orders').add({
      'buyerId': buyerId,
      'sellerId': sellerId,
      'status': 'pending',
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress,
      'items': items,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Transaction Methods
  Future<void> createTransaction({
    required String orderId,
    required String buyerId,
    required String sellerId,
    required double amount,
    required String paymentMethod,
  }) async {
    await _db.collection('transactions').add({
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'amount': amount,
      'status': 'pending',
      'paymentMethod': paymentMethod,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

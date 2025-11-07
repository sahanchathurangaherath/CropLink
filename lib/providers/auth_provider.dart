import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_details.dart';

class AuthProvider with ChangeNotifier {
  final _auth = AuthService();
  User? _user;
  String _role = 'buyer'; // default
  UserDetails? _userDetails;

  AuthProvider() {
    _auth.onAuthStateChanged.listen((u) async {
      _user = u;
      if (u != null) {
        // Load role from Firestore if present
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(u.uid)
              .get();
          if (doc.exists && doc.data()!.containsKey('role')) {
            _role = (doc['role'] as String?) ?? 'buyer';
          } else {
            _role = 'buyer';
          }
        } catch (_) {
          _role = 'buyer';
        }
      } else {
        _role = 'buyer';
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get signedIn => _user != null;
  String get role => _role;
  UserDetails? get userDetails => _userDetails;

  Future<void> setRole(String r) async {
    _role = r;
    notifyListeners();
    final u = _user;
    if (u != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(u.uid)
            .set({'role': r}, SetOptions(merge: true));
      } catch (_) {
        // ignore firestore errors for now; UI already updated
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signIn(email, password);
  }

  Future<void> signUp(String email, String password) async {
    await _auth.signUp(email, password);
  }

  Future<void> signOut() => _auth.signOut();

  // Save user details to Firestore and update provider state
  Future<void> saveUserDetails(UserDetails details) async {
    try {
      final uid = details.uid.isNotEmpty ? details.uid : (_user?.uid ?? '');
      if (uid.isEmpty) throw Exception('No user id available to save details.');

      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final data = {
        'email': details.email,
        'fullName': details.fullName,
        'phoneNumber': details.phoneNumber,
        'address': details.address,
        'city': details.city,
        'district': details.district,
        'postalCode': details.postalCode,
        'role': details.role,
      };

      await docRef.set(data, SetOptions(merge: true));
      _userDetails = details;
      notifyListeners();
    } catch (e) {
      print('Error in saveUserDetails: $e');
      rethrow;
    }
  }

  Future<UserDetails?> loadUserDetails() async {
    if (user == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      _userDetails = UserDetails(
        uid: user!.uid,
        email: (data['email'] as String?) ?? (user!.email ?? ''),
        fullName: (data['fullName'] as String?) ?? '',
        phoneNumber: (data['phoneNumber'] as String?) ?? '',
        address: (data['address'] as String?) ?? '',
        city: (data['city'] as String?) ?? '',
        district: (data['district'] as String?) ?? '',
        postalCode: (data['postalCode'] as String?) ?? '',
        role: (data['role'] as String?) ?? _role,
      );

      notifyListeners();
      return _userDetails;
    } catch (e) {
      print('Error loading user details: $e');
      return null;
    }
  }

  Future<bool> updateUserDetails(UserDetails details) async {
    // ensure we have a uid to update
    final uid = details.uid.isNotEmpty ? details.uid : (_user?.uid ?? '');
    if (uid.isEmpty) {
      print('No user id available to update details.');
      return false;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final data = {
        'email': details.email,
        'fullName': details.fullName,
        'phoneNumber': details.phoneNumber,
        'address': details.address,
        'city': details.city,
        'district': details.district,
        'postalCode': details.postalCode,
        'role': details.role,
      };

      // Use set with merge to update only provided fields
      await docRef.set(data, SetOptions(merge: true));

      _userDetails = details;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user details: $e');
      return false;
    }
  }
}

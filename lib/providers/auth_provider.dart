import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final _auth = AuthService();
  User? _user;
  String _role = 'buyer'; // default

  AuthProvider() {
    _auth.onAuthStateChanged.listen((u) async {
      _user = u;
      if (u != null) {
        // Load role from Firestore if present
        try {
          final doc =
              await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
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
}

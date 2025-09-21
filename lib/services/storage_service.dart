import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadProductImage(File file, String uid) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    final ref = _storage.ref('products/$uid/$name');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }
}

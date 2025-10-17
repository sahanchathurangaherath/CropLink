import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024, // Limit image size
        maxHeight: 1024,
        imageQuality: 80, // Compress image
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Upload product image
  Future<String> uploadProductImage(File file, String userId) async {
    try {
      // Create unique filename
      final String fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';

      // Reference to storage location
      final ref = _storage.ref().child('products/$userId/$fileName');

      // Upload with metadata
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/${p.extension(file.path).substring(1)}',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete and get download URL
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading product image: $e');
      throw Exception('Failed to upload product image: $e');
    }
  }

  // Upload subcategory image
  Future<String?> uploadSubcategoryImage(
    File file,
    String categoryId,
    String subcategoryName,
  ) async {
    try {
      // Create unique filename
      final String fileName =
          'subcategory_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';

      // Reference to storage location
      final ref = _storage.ref().child(
          'categories/$categoryId/subcategories/$subcategoryName/$fileName');

      // Upload with metadata
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/${p.extension(file.path).substring(1)}',
          customMetadata: {
            'categoryId': categoryId,
            'subcategoryName': subcategoryName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete and get download URL
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading subcategory image: $e');
      return null;
    }
  }

  // Upload category image
  Future<String?> uploadCategoryImage(File file, String categoryName) async {
    try {
      // Create unique filename
      final String fileName =
          'category_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';

      // Reference to storage location
      final ref = _storage.ref().child('categories/$categoryName/$fileName');

      // Upload with metadata
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'category': categoryName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL after upload completes
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Category image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading category image: $e');
      return null;
    }
  }

  // Upload item image
  Future<String?> uploadItemImage(
    File file,
    String categoryId,
    String subcategoryId,
    String itemName,
  ) async {
    try {
      // Create unique filename
      final String fileName =
          'item_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';

      // Reference to storage location
      final ref = _storage
          .ref()
          .child('items/$categoryId/$subcategoryId/$itemName/$fileName');

      // Upload with metadata
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'category': categoryId,
            'subcategory': subcategoryId,
            'itemName': itemName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL after upload completes
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Item image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading item image: $e');
      return null;
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted successfully: $imageUrl');
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}

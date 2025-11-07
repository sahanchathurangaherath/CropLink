import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
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

  // Helper: save file to local app directory under a relative path and return saved path
  Future<String> _saveFileLocally(
      File file, String relativeDir, String fileName) async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    final String targetDirPath = p.join(baseDir.path, relativeDir);
    final Directory targetDir = Directory(targetDirPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final String destPath = p.join(targetDir.path, fileName);
    final File saved = await file.copy(destPath);
    return saved.path;
  }

  // Upload product image -> now saves locally and returns local path
  Future<String> uploadProductImage(File file, String userId) async {
    try {
      final String fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final String relativeDir = p.join('products', userId);
      final String savedPath =
          await _saveFileLocally(file, relativeDir, fileName);
      return savedPath;
    } catch (e) {
      print('Error saving product image locally: $e');
      throw Exception('Failed to save product image: $e');
    }
  }

  // Upload subcategory image -> saves locally and returns local path
  Future<String?> uploadSubcategoryImage(
    File file,
    String categoryId,
    String subcategoryName,
  ) async {
    try {
      final String fileName =
          'subcategory_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final String relativeDir =
          p.join('categories', categoryId, 'subcategories', subcategoryName);
      final String savedPath =
          await _saveFileLocally(file, relativeDir, fileName);
      return savedPath;
    } catch (e) {
      print('Error saving subcategory image locally: $e');
      return null;
    }
  }

  // Upload category image -> saves locally and returns local path
  Future<String?> uploadCategoryImage(File file, String categoryName) async {
    try {
      final String fileName =
          'category_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final String relativeDir = p.join('categories', categoryName);
      final String savedPath =
          await _saveFileLocally(file, relativeDir, fileName);
      print('Category image saved locally: $savedPath');
      return savedPath;
    } catch (e) {
      print('Error saving category image locally: $e');
      return null;
    }
  }

  // Upload item image -> saves locally and returns local path
  Future<String?> uploadItemImage(
    File file,
    String categoryId,
    String subcategoryId,
    String itemName,
  ) async {
    try {
      final String fileName =
          'item_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final String relativeDir =
          p.join('items', categoryId, subcategoryId, itemName);
      final String savedPath =
          await _saveFileLocally(file, relativeDir, fileName);
      print('Item image saved locally: $savedPath');
      return savedPath;
    } catch (e) {
      print('Error saving item image locally: $e');
      return null;
    }
  }

  // Delete image from local storage (pass the local path returned by upload)
  Future<void> deleteImage(String imagePath) async {
    try {
      final String path = imagePath.replaceFirst('file://', '');
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('Image deleted successfully: $imagePath');
      } else {
        print('Image not found for deletion: $imagePath');
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> saveImage(
      String folder, String fileName, File imageFile) async {
    final path = await _localPath;
    final folderPath = '$path/$folder';
    final folderDir = Directory(folderPath);
    if (!await folderDir.exists()) {
      await folderDir.create(recursive: true);
    }

    final String filePath = '$folderPath/$fileName';
    await imageFile.copy(filePath);
    return filePath;
  }

  static Future<File?> getImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Handle or ignore deletion errors
    }
  }
}

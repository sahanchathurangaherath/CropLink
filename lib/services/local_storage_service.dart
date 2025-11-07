import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  static Future<void> saveFile(String fileName, List<int> bytes) async {
    try {
      final file = await getLocalFile(fileName);
      await file.writeAsBytes(bytes);
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  static Future<File?> getFile(String fileName) async {
    try {
      final file = await getLocalFile(fileName);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteFile(String fileName) async {
    try {
      final file = await getLocalFile(fileName);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

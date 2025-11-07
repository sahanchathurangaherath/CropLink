import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final File? selectedImage;
  final Function(File) onImageSelected;
  final Function() onImageRemoved;
  final String placeholder;
  final double height;
  final double width;

  const ImageUploadWidget({
    super.key,
    required this.selectedImage,
    required this.onImageSelected,
    required this.onImageRemoved,
    this.placeholder = 'Add Image',
    this.height = 200,
    this.width = double.infinity,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  Future<void> _pickImage(BuildContext context) async {
    final storageService = StorageService();

    // Show image source selection dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Image Source'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
              ),
            ),
          ],
        );
      },
    );

    if (source != null) {
      final File? image = await storageService.pickImage(source: source);
      if (image != null) {
        widget.onImageSelected(image);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: widget.selectedImage != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: const Color.fromRGBO(255, 255, 255, 0.8),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onImageRemoved,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: () => _pickImage(context),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.placeholder,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

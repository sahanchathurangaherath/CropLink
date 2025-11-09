import 'dart:io';
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class LocalImageWidget extends StatelessWidget {
  final String fileName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LocalImageWidget({
    super.key,
    required this.fileName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: LocalStorageService.getImage(fileName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return errorWidget ??
              const Center(child: Icon(Icons.error_outline, color: Colors.red));
        }

        return Image.file(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                const Center(
                    child: Icon(Icons.error_outline, color: Colors.red));
          },
        );
      },
    );
  }
}

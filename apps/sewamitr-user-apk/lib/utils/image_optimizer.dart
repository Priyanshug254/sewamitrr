import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageOptimizer {
  /// Compress an image file before uploading
  /// Reduces file size by 60-80% while maintaining quality
  static Future<XFile?> compressImage(
    XFile imageFile, {
    int quality = 70,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return XFile(result.path);
      }
      return null;
    } catch (e) {
      print('Image compression error: $e');
      return imageFile; // Return original if compression fails
    }
  }

  /// Compress image from bytes (useful for web)
  static Future<Uint8List?> compressImageBytes(
    Uint8List bytes, {
    int quality = 70,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      print('Image compression error: $e');
      return bytes; // Return original if compression fails
    }
  }

  /// Get compressed file size in MB
  static Future<double> getFileSizeMB(String filePath) async {
    final file = File(filePath);
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Check if image needs compression
  static Future<bool> shouldCompress(String filePath, {double maxSizeMB = 1.0}) async {
    final sizeMB = await getFileSizeMB(filePath);
    return sizeMB > maxSizeMB;
  }
}
